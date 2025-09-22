import { useState, useMemo, useEffect } from "react";
import axios from "axios";
import {
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  ComposedChart,
} from "recharts";

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      REACT_APP_API_URL?: string;
    }
  }
}

// --- TYPES ---
interface Indicator {
  id: string;
  name: string;
  unit?: string;
}

interface Geography {
  country: { code: string; name: string };
  states: { code: string; name: string }[];
  districts: { code: string; name: string; stateCode: string }[];
}

interface SeriesPoint {
  year: number;
  value: number | null;
  forecastValue?: number;
  isForcast?: boolean;
}

// Add proper typing for the payload
interface MultiGeoPayload {
  indicator: string;
  geoCodes: string[];
  startYear?: number;
  endYear?: number;
}

// --- CONFIGURATION ---
const API_BASE_URL = "http://localhost:3000";
const COMPARE_COLORS = ["#8884d8", "#82ca9d", "#ffc658", "#ff7300", "#8dd1e1"];

function App() {
  // --- STATE MANAGEMENT ---

  const [question, setQuestion] = useState("How did GDP change over the last decade?");
  const [response, setResponse] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [startYear, setStartYear] = useState("2015");
  const [endYear, setEndYear] = useState("2025");
  const [selectedGeoCode, setSelectedGeoCode] = useState("IN");

  const [isComparing, setIsComparing] = useState(false);
  const [compareError, setCompareError] = useState<string | null>(null);
  const [indicatorsToCompare, setIndicatorsToCompare] = useState<Set<string>>(new Set());
  const [comparisonResult, setComparisonResult] = useState<any>(null);
  const [comparisonChartData, setComparisonChartData] = useState<any[] | null>(null);

  const [forecastYears, setForecastYears] = useState<number>(5);
  const [isForecasting, setIsForecasting] = useState<string | null>(null);

  // Dynamic data loading
  const [indicators, setIndicators] = useState<Indicator[]>([]);
  const [geography, setGeography] = useState<Geography | null>(null);
  const [isLoadingMeta, setIsLoadingMeta] = useState(true);

  const [multiGeoMode, setMultiGeoMode] = useState(false);
  const [selectedGeoCodes, setSelectedGeoCodes] = useState<Set<string>>(new Set(["IN"]));
  const [selectedIndicator, setSelectedIndicator] = useState<string>("gdp_per_capita");
  const [multiGeoData, setMultiGeoData] = useState<any>(null);
  const [isLoadingMultiGeo, setIsLoadingMultiGeo] = useState(false);

  // --- LOAD METADATA ON COMPONENT MOUNT ---
  useEffect(() => {
    const loadMetadata = async () => {
      try {
        setIsLoadingMeta(true);
        const [indicatorsRes, geographyRes] = await Promise.all([
          axios.get(`${API_BASE_URL}/indicators`),
          axios.get(`${API_BASE_URL}/geography`)
        ]);
        
        setIndicators(indicatorsRes.data);
        setGeography(geographyRes.data);
        
        // Set default indicator if available
        if (indicatorsRes.data.length > 0) {
          setSelectedIndicator(indicatorsRes.data[0].id);
        }
      } catch (err) {
        console.error('Failed to load metadata:', err);
        setError('Failed to load application data. Please check if the server is running.');
      } finally {
        setIsLoadingMeta(false);
      }
    };

    loadMetadata();
  }, []);

  // --- API FUNCTIONS ---

  const askQuestion = async () => {
    setIsLoading(true);
    setError(null);
    setResponse(null);
    try {
      const payload: any = { 
        question, 
        geoCode: selectedGeoCode 
      };
      
      if (startYear && !isNaN(Number(startYear))) payload.startYear = Number(startYear);
      if (endYear && !isNaN(Number(endYear))) payload.endYear = Number(endYear);

      const res = await axios.post(`${API_BASE_URL}/ask`, payload);
      setResponse(res.data);
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.error || "Failed to fetch data. Please ensure the server is running and accessible.");
    } finally {
      setIsLoading(false);
    }
  };
  
  const runComparison = async () => {
    if (indicatorsToCompare.size !== 2) {
      setCompareError("Please select exactly two indicators to compare.");
      return;
    }
    setIsComparing(true);
    setCompareError(null);
    setComparisonResult(null);
    setComparisonChartData(null);

    try {
      const indicators = Array.from(indicatorsToCompare);
      const [corrRes, seriesRes] = await Promise.all([
        axios.post(`${API_BASE_URL}/compare`, { 
          indicators, 
          geoCode: selectedGeoCode 
        }),
        axios.post(`${API_BASE_URL}/compare-series`, { 
          indicators, 
          geoCode: selectedGeoCode 
        })
      ]);
      
      setComparisonResult(corrRes.data);
      setComparisonChartData(seriesRes.data.series);
    } catch (err: any) {
      console.error(err);
      setCompareError(err.response?.data?.error || "Failed to run comparison.");
    } finally {
      setIsComparing(false);
    }
  };

  const runForecast = async (indicator: string) => {
    const originalSeries = response.series[indicator];
    if (!originalSeries || originalSeries.length < 2) return;

    setIsForecasting(indicator);
    try {
      const validSeries = originalSeries.filter((p: SeriesPoint) => p.value !== null && p.value !== undefined);
      
      if (validSeries.length < 2) {
        throw new Error('Not enough valid data points for forecasting');
      }

      const res = await axios.post(`${API_BASE_URL}/forecast`, {
        series: validSeries,
        forecastYears: forecastYears,
      });
      
      setResponse((prev: any) => ({
        ...prev,
        series: { ...prev.series, [indicator]: res.data.series }
      }));
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.error || 'Forecasting failed');
    } finally {
      setIsForecasting(null);
    }
  };

  const runMultiGeoAnalysis = async () => {
    if (selectedGeoCodes.size === 0) return;
    
    setIsLoadingMultiGeo(true);
    setMultiGeoData(null);
    
    try {
      // Fix: Properly type the payload object
      const payload: MultiGeoPayload = {
        indicator: selectedIndicator,
        geoCodes: Array.from(selectedGeoCodes),
      };
      
      // Fix: Add conditional properties correctly
      if (startYear && !isNaN(Number(startYear))) {
        payload.startYear = Number(startYear);
      }
      if (endYear && !isNaN(Number(endYear))) {
        payload.endYear = Number(endYear);
      }

      const res = await axios.post(`${API_BASE_URL}/multi-geo`, payload);
      setMultiGeoData(res.data);
    } catch (err: any) {
      console.error(err);
      setError(err.response?.data?.error || "Failed to load multi-geo data.");
    } finally {
      setIsLoadingMultiGeo(false);
    }
  };

  // --- HELPERS & MEMOS ---

  const handleCompareToggle = (indicatorId: string) => {
    setIndicatorsToCompare(prev => {
      const newSet = new Set(prev);
      if (newSet.has(indicatorId)) {
        newSet.delete(indicatorId);
      } else if (newSet.size < 2) {
        newSet.add(indicatorId);
      }
      return newSet;
    });
  };

  const handleGeoToggle = (geoCode: string) => {
    setSelectedGeoCodes(prev => {
      const newSet = new Set(prev);
      if (newSet.has(geoCode)) {
        newSet.delete(geoCode);
      } else {
        newSet.add(geoCode);
      }
      return newSet;
    });
  };

  const formattedSummary = useMemo(() => {
    if (!response?.summary) return null;
    return Object.entries(response.summary).map(([indicator, stats]: [string, any]) => ({
      indicator,
      ...stats
    }));
  }, [response]);

  const getGeoName = (code: string): string => {
    if (!geography) return code;
    
    if (geography.country.code === code) return geography.country.name;
    
    const state = geography.states.find(s => s.code === code);
    if (state) return state.name;
    
    const district = geography.districts.find(d => d.code === code);
    if (district) return district.name;
    
    return code;
  };

  const allGeoCodes = useMemo(() => {
    if (!geography) return [];
    return [
      geography.country,
      ...geography.states,
      ...geography.districts
    ];
  }, [geography]);

  const formatMultiGeoChartData = useMemo(() => {
    if (!multiGeoData) return [];
    
    const yearMap: Record<number, any> = {};
    
    Object.entries(multiGeoData.data).forEach(([geoCode, series]: [string, any]) => {
      series.forEach((point: SeriesPoint) => {
        if (!yearMap[point.year]) {
          yearMap[point.year] = { year: point.year };
        }
        yearMap[point.year][geoCode] = point.value;
      });
    });
    
    return Object.values(yearMap).sort((a: any, b: any) => a.year - b.year);
  }, [multiGeoData]);

  // --- LOADING STATE ---
  if (isLoadingMeta) {
    return (
      <div className="app-container">
        <div className="loading-spinner">
          <h2>Loading Dharana Dashboard...</h2>
          <p>Connecting to database and loading metadata...</p>
        </div>
      </div>
    );
  }

  // --- RENDER ---

  return (
    <div className="app-container">
      <h1 className="app-title">📊 Dharana Dashboard</h1>

      {/* Mode Toggle */}
      <div className="card">
        <div className="mode-toggle">
          <button 
            onClick={() => setMultiGeoMode(false)} 
            className={!multiGeoMode ? "mode-button active" : "mode-button"}
          >
            Question Mode
          </button>
          <button 
            onClick={() => setMultiGeoMode(true)} 
            className={multiGeoMode ? "mode-button active" : "mode-button"}
          >
            Multi-Geography Analysis
          </button>
        </div>
      </div>

      {!multiGeoMode ? (
        <>
          {/* Main Controls Card */}
          <div className="card">
            <div className="input-group">
              <input
                type="text"
                placeholder="Ask a question..."
                value={question}
                onChange={(e) => setQuestion(e.target.value)}
                className="question-input"
                onKeyDown={(e) => e.key === 'Enter' && askQuestion()}
                disabled={isLoading}
              />
              <button onClick={askQuestion} className="ask-button" disabled={isLoading || !question}>
                {isLoading ? "Analyzing..." : "Ask"}
              </button>
            </div>
            <div className="filter-group">
              <select value={selectedGeoCode} onChange={e => setSelectedGeoCode(e.target.value)} className="filter-input">
                {allGeoCodes.map((geo) => (
                  <option key={geo.code} value={geo.code}>{geo.name}</option>
                ))}
              </select>
              <input type="number" placeholder="Start Year" value={startYear} onChange={e => setStartYear(e.target.value)} className="filter-input" />
              <input type="number" placeholder="End Year" value={endYear} onChange={e => setEndYear(e.target.value)} className="filter-input" />
            </div>
          </div>
          
          {/* Compare Indicators Card */}
          <div className="card">
            <h2 className="card-title">Compare Indicators</h2>
            <div className="compare-controls">
              <div className="checkbox-group">
                {indicators.map((indicator) => (
                  <label key={indicator.id} className="checkbox-label">
                    <input 
                      type="checkbox" 
                      checked={indicatorsToCompare.has(indicator.id)} 
                      onChange={() => handleCompareToggle(indicator.id)} 
                    />
                    {indicator.name} {indicator.unit && `(${indicator.unit})`}
                  </label>
                ))}
              </div>
              <button onClick={runComparison} className="ask-button" disabled={isComparing || indicatorsToCompare.size !== 2}>
                {isComparing ? "Comparing..." : "Compare"}
              </button>
            </div>
            {compareError && <p className="error-message">{compareError}</p>}
            {comparisonResult && (
              <div className="summary-card stat-card">
                <h3>Correlation Result</h3>
                <p className="stat-value">{Number(comparisonResult.correlation).toFixed(4)}</p>
                <p className="stat-label">Pearson Coefficient ({comparisonResult.dataPoints} data points)</p>
              </div>
            )}
          </div>

          {/* Comparison Chart */}
          {comparisonChartData && (
            <div className="card">
              <h3 className="card-title">Comparison Plot for {getGeoName(selectedGeoCode)}</h3>
              <div className="chart-container">
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={comparisonChartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                    <XAxis dataKey="year" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    {Array.from(indicatorsToCompare).map((indicatorId, index) => (
                      <Line
                        key={indicatorId}
                        type="monotone"
                        dataKey={indicatorId}
                        stroke={COMPARE_COLORS[index % COMPARE_COLORS.length]}
                        strokeWidth={2}
                        name={indicators.find(ind => ind.id === indicatorId)?.name || indicatorId}
                      />
                    ))}
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}
        </>
      ) : (
        /* Multi-Geography Mode */
        <div className="card">
          <h2 className="card-title">Multi-Geography Analysis</h2>
          <div className="multi-geo-controls">
            <div className="control-group">
              <label>Select Indicator:</label>
              <select 
                value={selectedIndicator} 
                onChange={e => setSelectedIndicator(e.target.value)} 
                className="filter-input"
              >
                {indicators.map((indicator) => (
                  <option key={indicator.id} value={indicator.id}>
                    {indicator.name} {indicator.unit && `(${indicator.unit})`}
                  </option>
                ))}
              </select>
            </div>
            
            <div className="control-group">
              <label>Select Geographies:</label>
              <div className="checkbox-group">
                {allGeoCodes.map((geo) => (
                  <label key={geo.code} className="checkbox-label">
                    <input 
                      type="checkbox" 
                      checked={selectedGeoCodes.has(geo.code)} 
                      onChange={() => handleGeoToggle(geo.code)} 
                    />
                    {geo.name}
                  </label>
                ))}
              </div>
            </div>
            
            <div className="filter-group">
              <input type="number" placeholder="Start Year" value={startYear} onChange={e => setStartYear(e.target.value)} className="filter-input" />
              <input type="number" placeholder="End Year" value={endYear} onChange={e => setEndYear(e.target.value)} className="filter-input" />
              <button onClick={runMultiGeoAnalysis} className="ask-button" disabled={isLoadingMultiGeo || selectedGeoCodes.size === 0}>
                {isLoadingMultiGeo ? "Loading..." : "Analyze"}
              </button>
            </div>
          </div>

          {multiGeoData && (
            <div className="multi-geo-results">
              <h3>Results for {indicators.find(ind => ind.id === selectedIndicator)?.name}</h3>
              <div className="chart-container">
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={formatMultiGeoChartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                    <XAxis dataKey="year" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    {Array.from(selectedGeoCodes).map((geoCode, index) => (
                      <Line
                        key={geoCode}
                        type="monotone"
                        dataKey={geoCode}
                        stroke={COMPARE_COLORS[index % COMPARE_COLORS.length]}
                        strokeWidth={2}
                        name={getGeoName(geoCode)}
                      />
                    ))}
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}
        </div>
      )}

      {error && <p className="error-message">{error}</p>}

      {/* Results from 'Ask' */}
      {response && !isLoading && !multiGeoMode && (
        <div className="response-container">
          <div className="summary-grid">
            {formattedSummary?.map(({ indicator, mean, pct_change, slope, count, latest, earliest }) => (
              <div key={indicator} className="summary-card">
                <h3 className="card-subtitle">
                  {indicators.find(ind => ind.id === indicator)?.name || indicator.replace(/_/g, ' ')}
                </h3>
                <div className="stats-grid">
                  <div className="stat-card">
                    <p className="stat-value">{mean ? Number(mean).toFixed(2) : 'N/A'}</p>
                    <p className="stat-label">Mean</p>
                  </div>
                  <div className="stat-card">
                    <p className="stat-value">{pct_change ? Number(pct_change).toFixed(2) + '%' : 'N/A'}</p>
                    <p className="stat-label">% Change</p>
                  </div>
                  <div className="stat-card">
                    <p className="stat-value">{slope ? Number(slope).toFixed(2) : 'N/A'}</p>
                    <p className="stat-label">Trend Slope</p>
                  </div>
                  <div className="stat-card">
                    <p className="stat-value">{count || 0}</p>
                    <p className="stat-label">Data Points</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {Object.keys(response.series).map((indicator) => (
            <div key={indicator} className="card">
              <h3 className="card-title">
                {indicators.find(ind => ind.id === indicator)?.name || indicator.replace(/_/g, ' ')}
                {indicators.find(ind => ind.id === indicator)?.unit && 
                  ` (${indicators.find(ind => ind.id === indicator)?.unit})`
                }
              </h3>
              <div className="chart-container">
                <ResponsiveContainer width="100%" height="100%">
                  <ComposedChart data={response.series[indicator]}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" />
                    <XAxis dataKey="year" />
                    <YAxis />
                    <Tooltip />
                    <Legend />
                    <Line 
                      type="monotone" 
                      dataKey="value" 
                      name="Historical" 
                      stroke="#2563eb" 
                      strokeWidth={2} 
                      dot={false}
                      connectNulls={false}
                    />
                    <Line 
                      type="monotone" 
                      dataKey="forecastValue" 
                      name="Forecast" 
                      stroke="#2563eb" 
                      strokeWidth={2} 
                      strokeDasharray="5 5" 
                      dot={false}
                      connectNulls={false}
                    />
                  </ComposedChart>
                </ResponsiveContainer>
              </div>
              <div className="forecast-controls">
                <input 
                  type="number" 
                  value={forecastYears} 
                  onChange={e => setForecastYears(Math.max(1, parseInt(e.target.value, 10) || 1))}
                  className="filter-input"
                  min="1"
                  max="20"
                />
                <button 
                  onClick={() => runForecast(indicator)} 
                  className="ask-button" 
                  disabled={isForecasting === indicator || !response.series[indicator] || response.series[indicator].length < 2}
                >
                  {isForecasting === indicator ? 'Forecasting..' : `Forecast ${forecastYears} Years`}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default App;