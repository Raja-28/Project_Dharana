import express, { Request, Response } from 'express';
import cors from 'cors';
import { getNeo4jSession } from './neo4j';
import * as compute from 'compute';

const app = express();

app.use(express.json());
app.use(cors());

console.log("✅ Rust WASM module loaded (sync)");

// --- CONFIGURATION ---
// Updated to include all indicators from the seed script
const indicatorMap: Record<string, string> = {
  literacy: 'rural_literacy_rate',
  employment: 'employment_rate',
  gdp: 'gdp_per_capita',
  mortality: 'infant_mortality_rate',
  water: 'clean_water_access',
  female: 'female_literacy_rate',
  unemployment: 'unemployment_rate',
  rural: 'rural_literacy_rate',
  clean: 'clean_water_access',
  infant: 'infant_mortality_rate',
  capita: 'gdp_per_capita'
};

// --- HELPER FUNCTIONS ---
function getNodeLabel(geoCode: string): string {
  if (geoCode === 'IN') return 'Country';
  if (['TN', 'MH', 'KA', 'UP', 'GJ', 'KL'].includes(geoCode)) return 'State';
  if (['BLR', 'LKO', 'MUM', 'CHE'].includes(geoCode)) return 'District';
  return 'Country'; // Default fallback
}

// --- API ENDPOINTS ---

app.get('/health', (_req: Request, res: Response) => {
  res.json({ ok: true, timestamp: new Date().toISOString() });
});

app.get('/geography', async (_req: Request, res: Response) => {
  try {
    const session = getNeo4jSession();
    
    const result = await session.run(`
      MATCH (c:Country)
      OPTIONAL MATCH (c)<-[:IN_COUNTRY]-(s:State)
      OPTIONAL MATCH (s)<-[:IN_STATE]-(d:District)
      RETURN 
        c.code as countryCode, c.name as countryName,
        collect(DISTINCT {code: s.code, name: s.name}) as states,
        collect(DISTINCT {code: d.code, name: d.name, stateCode: s.code}) as districts
    `);

    const geography = result.records.map(record => ({
      country: {
        code: record.get('countryCode'),
        name: record.get('countryName')
      },
      states: record.get('states').filter((s: any) => s.code !== null),
      districts: record.get('districts').filter((d: any) => d.code !== null)
    }));

    await session.close();
    res.json(geography[0] || { country: null, states: [], districts: [] });
  } catch (e: any) {
    console.error('Geography endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.get('/indicators', async (_req: Request, res: Response) => {
  try {
    const session = getNeo4jSession();
    
    const result = await session.run(`
      MATCH (i:Indicator)
      RETURN i.id as id, i.name as name, i.unit as unit
      ORDER BY i.name
    `);

    const indicators = result.records.map(record => ({
      id: record.get('id'),
      name: record.get('name'),
      unit: record.get('unit') || ''
    }));

    await session.close();
    res.json(indicators);
  } catch (e: any) {
    console.error('Indicators endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/ask', async (req: Request, res: Response) => {
  try {
    const { question, startYear, endYear, geoCode = 'IN' } = req.body ?? {};
    if (!question) {
      return res.status(400).json({ error: 'Missing question' });
    }

    const lowerQ = question.toLowerCase();
    const matchedIndicators = Object.keys(indicatorMap)
      .filter(key => lowerQ.includes(key))
      .map(key => indicatorMap[key]);

    // Default to GDP per capita if no keywords are matched
    const indicators = matchedIndicators.length > 0 ? matchedIndicators : ['gdp_per_capita'];
    const nodeLabel = getNodeLabel(geoCode);

    const session = getNeo4jSession();
    const seriesByIndicator: Record<string, { year: number; value: number }[]> = {};
    const summaryByIndicator: Record<string, any> = {};

    for (const indicator of indicators) {
      const queryParams: any = { indicator, geoCode };
      let yearFilterClause = '';

      if (startYear && endYear) {
        yearFilterClause = 'AND s.year >= $startYear AND s.year <= $endYear';
        queryParams.startYear = Number(startYear);
        queryParams.endYear = Number(endYear);
      }
      
      // Updated query to match the correct schema
      const result = await session.run(
        `
          MATCH (g:${nodeLabel} {code: $geoCode})<-[:MEASURED_IN]-(s:Series {indicator: $indicator})
          WHERE s.value IS NOT NULL ${yearFilterClause}
          RETURN s.year AS year, s.value AS value
          ORDER BY year
        `,
        queryParams
      );

      const series = result.records.map(r => ({
        year: r.get('year').toNumber ? r.get('year').toNumber() : r.get('year'),
        value: Number(r.get('value')),
      }));

      seriesByIndicator[indicator] = series;
      
      if (series.length > 1) {
        const values = new Float64Array(series.map(p => p.value));
        summaryByIndicator[indicator] = {
          mean: compute.mean(values),
          pct_change: compute.pct_change(values),
          slope: compute.slope(values),
          count: series.length,
          latest: series[series.length - 1]?.value || null,
          earliest: series[0]?.value || null
        };
      } else if (series.length === 1) {
        summaryByIndicator[indicator] = {
          mean: series[0].value,
          pct_change: 0,
          slope: 0,
          count: 1,
          latest: series[0].value,
          earliest: series[0].value
        };
      } else {
        summaryByIndicator[indicator] = {
          mean: null,
          pct_change: null,
          slope: null,
          count: 0,
          latest: null,
          earliest: null
        };
      }
    }

    await session.close();
    res.json({ 
      question, 
      geoCode,
      indicators, 
      summary: summaryByIndicator, 
      series: seriesByIndicator 
    });

  } catch (e: any) {
    console.error('Ask endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/compare', async (req: Request, res: Response) => {
  try {
    const { indicators, geoCode = 'IN' } = req.body ?? {};
    if (!Array.isArray(indicators) || indicators.length !== 2) {
      return res.status(400).json({ error: 'Please provide exactly 2 indicators' });
    }
    
    const nodeLabel = getNodeLabel(geoCode);
    const session = getNeo4jSession();
    const seriesData: Record<string, number[]> = {};

    for (const indicator of indicators) {
      const result = await session.run(
        `
          MATCH (g:${nodeLabel} {code: $geoCode})<-[:MEASURED_IN]-(s:Series {indicator: $indicator})
          WHERE s.value IS NOT NULL
          RETURN s.year AS year, s.value AS value
          ORDER BY year
        `,
        { indicator, geoCode }
      );
      seriesData[indicator] = result.records.map(r => Number(r.get('value')));
    }
    await session.close();

    if (seriesData[indicators[0]].length !== seriesData[indicators[1]].length) {
      return res.status(400).json({ 
        error: 'Cannot compare indicators with different numbers of data points.',
        details: {
          [indicators[0]]: seriesData[indicators[0]].length,
          [indicators[1]]: seriesData[indicators[1]].length
        }
      });
    }

    if (seriesData[indicators[0]].length === 0) {
      return res.status(400).json({ error: 'No data found for the specified indicators and geography.' });
    }

    const a = new Float64Array(seriesData[indicators[0]]);
    const b = new Float64Array(seriesData[indicators[1]]);
    const corr = compute.pearson(a, b);
    
    res.json({ 
      indicators, 
      geoCode,
      correlation: corr,
      dataPoints: a.length
    });
  } catch (e: any) {
    console.error('Compare endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/compare-series', async (req: Request, res: Response) => {
  try {
    const { indicators, geoCode = 'IN' } = req.body ?? {};
    if (!Array.isArray(indicators) || indicators.length !== 2) {
      return res.status(400).json({ error: 'Please provide exactly 2 indicators' });
    }

    const nodeLabel = getNodeLabel(geoCode);
    const session = getNeo4jSession();
    const seriesData: Record<string, { year: number; value: number }[]> = {};

    for (const indicator of indicators) {
      const result = await session.run(
        `
          MATCH (g:${nodeLabel} {code: $geoCode})<-[:MEASURED_IN]-(s:Series {indicator: $indicator})
          WHERE s.value IS NOT NULL
          RETURN s.year AS year, s.value AS value
          ORDER BY year
        `,
        { indicator, geoCode }
      );
      seriesData[indicator] = result.records.map(r => ({
        year: r.get('year').toNumber ? r.get('year').toNumber() : r.get('year'),
        value: Number(r.get('value')),
      }));
    }
    await session.close();

    // Merge series data by year
    const yearMap: Record<number, { year: number; [key: string]: number }> = {};
    for (const indicator of indicators) {
      for (const point of seriesData[indicator]) {
        if (!yearMap[point.year]) {
          yearMap[point.year] = { year: point.year };
        }
        yearMap[point.year][indicator] = point.value;
      }
    }
    
    const mergedSeries = Object.values(yearMap)
      .filter(point => indicators.every(ind => point[ind] !== undefined))
      .sort((a, b) => a.year - b.year);
      
    res.json({ 
      indicators, 
      geoCode,
      series: mergedSeries,
      dataPoints: mergedSeries.length
    });
  } catch (e: any) {
    console.error('Compare-series endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/forecast', async (req: Request, res: Response) => {
  try {
    const { series, forecastYears } = req.body;
    if (!series || !forecastYears || series.length < 2) {
      return res.status(400).json({ 
        error: 'Missing series data or years to forecast. A minimum of two data points is required.' 
      });
    }

    const values = new Float64Array(series.map((p: any) => p.value));
    const slope = compute.slope(values);
    
    const lastPoint = series[series.length - 1];
    const forecast = [];

    for (let i = 1; i <= forecastYears; i++) {
      forecast.push({
        year: lastPoint.year + i,
        value: null, // Historical value is null
        forecastValue: lastPoint.value + (slope * i),
        isForcast: true
      });
    }
    
    const fullSeries = series.map((p: any) => ({ 
      ...p, 
      forecastValue: p.value,
      isForcast: false 
    })).concat(forecast);

    res.json({ 
      series: fullSeries,
      slope,
      baseValue: lastPoint.value,
      forecastYears
    });
  } catch (e: any) {
    console.error('Forecast endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

app.post('/multi-geo', async (req: Request, res: Response) => {
  try {
    const { indicator, geoCodes, startYear, endYear } = req.body ?? {};
    if (!indicator || !Array.isArray(geoCodes) || geoCodes.length === 0) {
      return res.status(400).json({ error: 'Missing indicator or geoCodes array' });
    }

    const session = getNeo4jSession();
    const results: Record<string, { year: number; value: number }[]> = {};

    for (const geoCode of geoCodes) {
      const nodeLabel = getNodeLabel(geoCode);
      const queryParams: any = { indicator, geoCode };
      let yearFilterClause = '';

      if (startYear && endYear) {
        yearFilterClause = 'AND s.year >= $startYear AND s.year <= $endYear';
        queryParams.startYear = Number(startYear);
        queryParams.endYear = Number(endYear);
      }

      const result = await session.run(
        `
          MATCH (g:${nodeLabel} {code: $geoCode})<-[:MEASURED_IN]-(s:Series {indicator: $indicator})
          WHERE s.value IS NOT NULL ${yearFilterClause}
          RETURN s.year AS year, s.value AS value, g.name AS geoName
          ORDER BY year
        `,
        queryParams
      );

      results[geoCode] = result.records.map(r => ({
        year: r.get('year').toNumber ? r.get('year').toNumber() : r.get('year'),
        value: Number(r.get('value')),
        geoName: r.get('geoName')
      }));
    }

    await session.close();
    res.json({ 
      indicator, 
      geoCodes,
      data: results
    });
  } catch (e: any) {
    console.error('Multi-geo endpoint error:', e);
    res.status(500).json({ error: e.message || String(e) });
  }
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: any) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`🚀 API server listening on port ${port}`);
  console.log(`📊 Available endpoints:`);
  console.log(`   GET  /health - Health check`);
  console.log(`   GET  /geography - Available geographies`);
  console.log(`   GET  /indicators - Available indicators`);
  console.log(`   POST /ask - Natural language queries`);
  console.log(`   POST /compare - Compare two indicators`);
  console.log(`   POST /compare-series - Compare series data`);
  console.log(`   POST /forecast - Forecast future values`);
  console.log(`   POST /multi-geo - Multi-geography analysis`);
});