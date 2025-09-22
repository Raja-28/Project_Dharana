// Best practice: Clear all existing data for a fresh start
MATCH (n) DETACH DELETE n;

// --- 1. Create Geography Hierarchy ---
CREATE (in:Country {code:'IN', name:'India'});

CREATE (tn:State {code:'TN', name:'Tamil Nadu'})
CREATE (mh:State {code:'MH', name:'Maharashtra'})
CREATE (ka:State {code:'KA', name:'Karnataka'})
CREATE (up:State {code:'UP', name:'Uttar Pradesh'})
CREATE (gj:State {code:'GJ', name:'Gujarat'})
CREATE (kl:State {code:'KL', name:'Kerala'});

CREATE (blr:District {code:'BLR', name:'Bengaluru'})
CREATE (lko:District {code:'LKO', name:'Lucknow'})
CREATE (mum:District {code:'MUM', name:'Mumbai'})
CREATE (che:District {code:'CHE', name:'Chennai'});

// Create hierarchical relationships
MATCH (in:Country {code:'IN'}), (tn:State {code:'TN'}) CREATE (tn)-[:IN_COUNTRY]->(in);
MATCH (in:Country {code:'IN'}), (mh:State {code:'MH'}) CREATE (mh)-[:IN_COUNTRY]->(in);
MATCH (in:Country {code:'IN'}), (ka:State {code:'KA'}) CREATE (ka)-[:IN_COUNTRY]->(in);
MATCH (in:Country {code:'IN'}), (up:State {code:'UP'}) CREATE (up)-[:IN_COUNTRY]->(in);
MATCH (in:Country {code:'IN'}), (gj:State {code:'GJ'}) CREATE (gj)-[:IN_COUNTRY]->(in);
MATCH (in:Country {code:'IN'}), (kl:State {code:'KL'}) CREATE (kl)-[:IN_COUNTRY]->(in);

MATCH (ka:State {code:'KA'}), (blr:District {code:'BLR'}) CREATE (blr)-[:IN_STATE]->(ka);
MATCH (up:State {code:'UP'}), (lko:District {code:'LKO'}) CREATE (lko)-[:IN_STATE]->(up);
MATCH (mh:State {code:'MH'}), (mum:District {code:'MUM'}) CREATE (mum)-[:IN_STATE]->(mh);
MATCH (tn:State {code:'TN'}), (che:District {code:'CHE'}) CREATE (che)-[:IN_STATE]->(tn);

// --- 2. Create Indicators ---
CREATE (lit:Indicator {id:'rural_literacy_rate', name:'Rural Literacy Rate', unit:'%'})
CREATE (emp:Indicator {id:'employment_rate', name:'Employment Rate', unit:'%'})
CREATE (gdp:Indicator {id:'gdp_per_capita', name:'GDP per Capita', unit:'USD'})
CREATE (imr:Indicator {id:'infant_mortality_rate', name:'Infant Mortality Rate', unit:'per 1000 live births'})
CREATE (h2o:Indicator {id:'clean_water_access', name:'Access to Clean Water', unit:'%'})
CREATE (flit:Indicator {id:'female_literacy_rate', name:'Female Literacy Rate', unit:'%'})
CREATE (unemp:Indicator {id:'unemployment_rate', name:'Unemployment Rate', unit:'%'});

// --- 3. Create Series Data for India ---
MATCH (in:Country {code:'IN'})
UNWIND range(2010, 2025) AS year
WITH in, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'IN', value: 55.0 + (year-2010)*0.8})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'IN', value: 38.0 + (year-2010)*0.35})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'IN', value: 1300.0 + (year-2010)*110})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'IN', value: 45.0 - (year-2010)*1.2})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'IN', value: 80.0 + (year-2010)*0.9})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'IN', value: 50.0 + (year-2010)*1.1})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'IN', value: 8.5 - (year-2010)*0.15})
WITH in, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(in)
CREATE (s_emp)-[:MEASURED_IN]->(in)
CREATE (s_gdp)-[:MEASURED_IN]->(in)
CREATE (s_imr)-[:MEASURED_IN]->(in)
CREATE (s_h2o)-[:MEASURED_IN]->(in)
CREATE (s_flit)-[:MEASURED_IN]->(in)
CREATE (s_unemp)-[:MEASURED_IN]->(in);

// Link indicators to India series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'IN'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'IN'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'IN'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'IN'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'IN'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'IN'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'IN'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 4. Create Series Data for Tamil Nadu ---
MATCH (tn:State {code:'TN'})
UNWIND range(2010, 2025) AS year
WITH tn, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'TN', value: 70.0 + (year-2010)*0.6})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'TN', value: 42.0 + (year-2010)*0.4})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'TN', value: 2000.0 + (year-2010)*160})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'TN', value: 20.0 - (year-2010)*0.8})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'TN', value: 92.0 + (year-2010)*0.5})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'TN', value: 73.0 + (year-2010)*0.8})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'TN', value: 5.0 - (year-2010)*0.1})
WITH tn, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(tn)
CREATE (s_emp)-[:MEASURED_IN]->(tn)
CREATE (s_gdp)-[:MEASURED_IN]->(tn)
CREATE (s_imr)-[:MEASURED_IN]->(tn)
CREATE (s_h2o)-[:MEASURED_IN]->(tn)
CREATE (s_flit)-[:MEASURED_IN]->(tn)
CREATE (s_unemp)-[:MEASURED_IN]->(tn);

// Link indicators to Tamil Nadu series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'TN'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'TN'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'TN'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'TN'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'TN'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'TN'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'TN'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 5. Create Series Data for Maharashtra ---
MATCH (mh:State {code:'MH'})
UNWIND range(2010, 2025) AS year
WITH mh, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'MH', value: 68.0 + (year-2010)*0.7})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'MH', value: 44.0 + (year-2010)*0.2})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'MH', value: 2400.0 + (year-2010)*180})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'MH', value: 25.0 - (year-2010)*1.0})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'MH', value: 88.0 + (year-2010)*0.7})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'MH', value: 75.0 + (year-2010)*0.9})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'MH', value: 4.5 - (year-2010)*0.05})
WITH mh, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(mh)
CREATE (s_emp)-[:MEASURED_IN]->(mh)
CREATE (s_gdp)-[:MEASURED_IN]->(mh)
CREATE (s_imr)-[:MEASURED_IN]->(mh)
CREATE (s_h2o)-[:MEASURED_IN]->(mh)
CREATE (s_flit)-[:MEASURED_IN]->(mh)
CREATE (s_unemp)-[:MEASURED_IN]->(mh);

// Link indicators to Maharashtra series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'MH'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'MH'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'MH'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'MH'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'MH'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'MH'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'MH'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 6. Create Series Data for Kerala ---
MATCH (kl:State {code:'KL'})
UNWIND range(2010, 2025) AS year
WITH kl, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'KL', value: 92.0 + (year-2010)*0.2})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'KL', value: 35.0 + (year-2010)*0.25})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'KL', value: 2100.0 + (year-2010)*140})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'KL', value: 10.0 - (year-2010)*0.4})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'KL', value: 95.0 + (year-2010)*0.3})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'KL', value: 91.0 + (year-2010)*0.3})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'KL', value: 9.8 - (year-2010)*0.2})
WITH kl, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(kl)
CREATE (s_emp)-[:MEASURED_IN]->(kl)
CREATE (s_gdp)-[:MEASURED_IN]->(kl)
CREATE (s_imr)-[:MEASURED_IN]->(kl)
CREATE (s_h2o)-[:MEASURED_IN]->(kl)
CREATE (s_flit)-[:MEASURED_IN]->(kl)
CREATE (s_unemp)-[:MEASURED_IN]->(kl);

// Link indicators to Kerala series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'KL'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'KL'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'KL'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'KL'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'KL'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'KL'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'KL'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 7. Create Series Data for Karnataka ---
MATCH (ka:State {code:'KA'})
UNWIND range(2010, 2025) AS year
WITH ka, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'KA', value: 65.0 + (year-2010)*0.8})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'KA', value: 50.0 + (year-2010)*0.3})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'KA', value: 2200.0 + (year-2010)*170})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'KA', value: 22.0 - (year-2010)*0.9})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'KA', value: 90.0 + (year-2010)*0.6})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'KA', value: 68.0 + (year-2010)*1.0})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'KA', value: 4.0 - (year-2010)*0.09})
WITH ka, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(ka)
CREATE (s_emp)-[:MEASURED_IN]->(ka)
CREATE (s_gdp)-[:MEASURED_IN]->(ka)
CREATE (s_imr)-[:MEASURED_IN]->(ka)
CREATE (s_h2o)-[:MEASURED_IN]->(ka)
CREATE (s_flit)-[:MEASURED_IN]->(ka)
CREATE (s_unemp)-[:MEASURED_IN]->(ka);

// Link indicators to Karnataka series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'KA'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'KA'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'KA'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'KA'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'KA'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'KA'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'KA'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 8. Create Series Data for Uttar Pradesh ---
MATCH (up:State {code:'UP'})
UNWIND range(2010, 2025) AS year
WITH up, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'UP', value: 45.0 + (year-2010)*1.2})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'UP', value: 32.0 + (year-2010)*0.2})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'UP', value: 800.0 + (year-2010)*60})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'UP', value: 60.0 - (year-2010)*1.5})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'UP', value: 70.0 + (year-2010)*1.1})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'UP', value: 40.0 + (year-2010)*1.3})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'UP', value: 10.2 - (year-2010)*0.2})
WITH up, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(up)
CREATE (s_emp)-[:MEASURED_IN]->(up)
CREATE (s_gdp)-[:MEASURED_IN]->(up)
CREATE (s_imr)-[:MEASURED_IN]->(up)
CREATE (s_h2o)-[:MEASURED_IN]->(up)
CREATE (s_flit)-[:MEASURED_IN]->(up)
CREATE (s_unemp)-[:MEASURED_IN]->(up);

// Link indicators to Uttar Pradesh series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'UP'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'UP'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'UP'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'UP'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'UP'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'UP'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'UP'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 9. Create Series Data for Gujarat ---
MATCH (gj:State {code:'GJ'})
UNWIND range(2010, 2025) AS year
WITH gj, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'GJ', value: 70.0 + (year-2010)*0.9})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'GJ', value: 45.0 + (year-2010)*0.1})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'GJ', value: 2500.0 + (year-2010)*190})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'GJ', value: 30.0 - (year-2010)*1.1})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'GJ', value: 90.0 + (year-2010)*0.6})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'GJ', value: 65.0 + (year-2010)*1.0})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'GJ', value: 2.5 - (year-2010)*0.02})
WITH gj, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(gj)
CREATE (s_emp)-[:MEASURED_IN]->(gj)
CREATE (s_gdp)-[:MEASURED_IN]->(gj)
CREATE (s_imr)-[:MEASURED_IN]->(gj)
CREATE (s_h2o)-[:MEASURED_IN]->(gj)
CREATE (s_flit)-[:MEASURED_IN]->(gj)
CREATE (s_unemp)-[:MEASURED_IN]->(gj);

// Link indicators to Gujarat series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'GJ'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'GJ'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'GJ'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'GJ'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'GJ'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'GJ'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'GJ'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 10. Create Series Data for Bengaluru District ---
MATCH (blr:District {code:'BLR'})
UNWIND range(2010, 2025) AS year
WITH blr, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'BLR', value: 85.0 + (year-2010)*0.4})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'BLR', value: 60.0 + (year-2010)*0.5})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'BLR', value: 5000.0 + (year-2010)*300})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'BLR', value: 15.0 - (year-2010)*0.5})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'BLR', value: 98.0 + (year-2010)*0.1})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'BLR', value: 87.0 + (year-2010)*0.5})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'BLR', value: 3.5 - (year-2010)*0.08})
WITH blr, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(blr)
CREATE (s_emp)-[:MEASURED_IN]->(blr)
CREATE (s_gdp)-[:MEASURED_IN]->(blr)
CREATE (s_imr)-[:MEASURED_IN]->(blr)
CREATE (s_h2o)-[:MEASURED_IN]->(blr)
CREATE (s_flit)-[:MEASURED_IN]->(blr)
CREATE (s_unemp)-[:MEASURED_IN]->(blr);

// Link indicators to Bengaluru series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'BLR'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'BLR'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'BLR'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'BLR'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'BLR'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'BLR'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'BLR'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 11. Create Series Data for Lucknow District ---
MATCH (lko:District {code:'LKO'})
UNWIND range(2010, 2025) AS year
WITH lko, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'LKO', value: 75.0 + (year-2010)*1.0})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'LKO', value: 40.0 + (year-2010)*0.3})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'LKO', value: 1500.0 + (year-2010)*90})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'LKO', value: 50.0 - (year-2010)*1.4})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'LKO', value: 80.0 + (year-2010)*1.0})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'LKO', value: 65.0 + (year-2010)*1.2})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'LKO', value: 9.0 - (year-2010)*0.25})
WITH lko, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(lko)
CREATE (s_emp)-[:MEASURED_IN]->(lko)
CREATE (s_gdp)-[:MEASURED_IN]->(lko)
CREATE (s_imr)-[:MEASURED_IN]->(lko)
CREATE (s_h2o)-[:MEASURED_IN]->(lko)
CREATE (s_flit)-[:MEASURED_IN]->(lko)
CREATE (s_unemp)-[:MEASURED_IN]->(lko);

// Link indicators to Lucknow series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'LKO'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'LKO'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'LKO'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'LKO'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'LKO'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'LKO'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'LKO'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 12. Create Series Data for Mumbai District ---
MATCH (mum:District {code:'MUM'})
UNWIND range(2010, 2025) AS year
WITH mum, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'MUM', value: 90.0 + (year-2010)*0.2})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'MUM', value: 58.0 + (year-2010)*0.25})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'MUM', value: 6000.0 + (year-2010)*350})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'MUM', value: 18.0 - (year-2010)*0.7})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'MUM', value: 97.0 + (year-2010)*0.15})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'MUM', value: 88.0 + (year-2010)*0.6})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'MUM', value: 5.2 - (year-2010)*0.1})
WITH mum, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(mum)
CREATE (s_emp)-[:MEASURED_IN]->(mum)
CREATE (s_gdp)-[:MEASURED_IN]->(mum)
CREATE (s_imr)-[:MEASURED_IN]->(mum)
CREATE (s_h2o)-[:MEASURED_IN]->(mum)
CREATE (s_flit)-[:MEASURED_IN]->(mum)
CREATE (s_unemp)-[:MEASURED_IN]->(mum);

// Link indicators to Mumbai series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'MUM'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'MUM'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'MUM'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'MUM'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'MUM'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'MUM'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'MUM'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 13. Create Series Data for Chennai District ---
MATCH (che:District {code:'CHE'})
UNWIND range(2010, 2025) AS year
WITH che, year
CREATE (s_lit:Series {year:year, indicator:'rural_literacy_rate', geo:'CHE', value: 88.0 + (year-2010)*0.3})
CREATE (s_emp:Series {year:year, indicator:'employment_rate', geo:'CHE', value: 55.0 + (year-2010)*0.4})
CREATE (s_gdp:Series {year:year, indicator:'gdp_per_capita', geo:'CHE', value: 4500.0 + (year-2010)*250})
CREATE (s_imr:Series {year:year, indicator:'infant_mortality_rate', geo:'CHE', value: 12.0 - (year-2010)*0.4})
CREATE (s_h2o:Series {year:year, indicator:'clean_water_access', geo:'CHE', value: 99.0 + (year-2010)*0.05})
CREATE (s_flit:Series {year:year, indicator:'female_literacy_rate', geo:'CHE', value: 89.0 + (year-2010)*0.4})
CREATE (s_unemp:Series {year:year, indicator:'unemployment_rate', geo:'CHE', value: 4.8 - (year-2010)*0.12})
WITH che, s_lit, s_emp, s_gdp, s_imr, s_h2o, s_flit, s_unemp
CREATE (s_lit)-[:MEASURED_IN]->(che)
CREATE (s_emp)-[:MEASURED_IN]->(che)
CREATE (s_gdp)-[:MEASURED_IN]->(che)
CREATE (s_imr)-[:MEASURED_IN]->(che)
CREATE (s_h2o)-[:MEASURED_IN]->(che)
CREATE (s_flit)-[:MEASURED_IN]->(che)
CREATE (s_unemp)-[:MEASURED_IN]->(che);

// Link indicators to Chennai series
MATCH (lit:Indicator {id:'rural_literacy_rate'}), (s:Series {indicator:'rural_literacy_rate', geo:'CHE'})
CREATE (lit)-[:HAS_SERIES]->(s);

MATCH (emp:Indicator {id:'employment_rate'}), (s:Series {indicator:'employment_rate', geo:'CHE'})
CREATE (emp)-[:HAS_SERIES]->(s);

MATCH (gdp:Indicator {id:'gdp_per_capita'}), (s:Series {indicator:'gdp_per_capita', geo:'CHE'})
CREATE (gdp)-[:HAS_SERIES]->(s);

MATCH (imr:Indicator {id:'infant_mortality_rate'}), (s:Series {indicator:'infant_mortality_rate', geo:'CHE'})
CREATE (imr)-[:HAS_SERIES]->(s);

MATCH (h2o:Indicator {id:'clean_water_access'}), (s:Series {indicator:'clean_water_access', geo:'CHE'})
CREATE (h2o)-[:HAS_SERIES]->(s);

MATCH (flit:Indicator {id:'female_literacy_rate'}), (s:Series {indicator:'female_literacy_rate', geo:'CHE'})
CREATE (flit)-[:HAS_SERIES]->(s);

MATCH (unemp:Indicator {id:'unemployment_rate'}), (s:Series {indicator:'unemployment_rate', geo:'CHE'})
CREATE (unemp)-[:HAS_SERIES]->(s);

// --- 14. Create Constraints and Indexes for Better Performance ---
CREATE CONSTRAINT country_code IF NOT EXISTS FOR (c:Country) REQUIRE c.code IS UNIQUE;
CREATE CONSTRAINT state_code IF NOT EXISTS FOR (s:State) REQUIRE s.code IS UNIQUE;
CREATE CONSTRAINT district_code IF NOT EXISTS FOR (d:District) REQUIRE d.code IS UNIQUE;
CREATE CONSTRAINT indicator_id IF NOT EXISTS FOR (i:Indicator) REQUIRE i.id IS UNIQUE;
CREATE CONSTRAINT series_composite IF NOT EXISTS FOR (s:Series) REQUIRE (s.year, s.indicator, s.geo) IS UNIQUE;

CREATE INDEX series_year IF NOT EXISTS FOR (s:Series) ON (s.year);
CREATE INDEX series_indicator IF NOT EXISTS FOR (s:Series) ON (s.indicator);
CREATE INDEX series_geo IF NOT EXISTS FOR (s:Series) ON (s.geo);
CREATE INDEX series_value IF NOT EXISTS FOR (s:Series) ON (s.value);

// --- 15. Verification Queries ---
// Check the data structure
MATCH (c:Country) RETURN COUNT(c) as countries;
MATCH (s:State) RETURN COUNT(s) as states;
MATCH (d:District) RETURN COUNT(d) as districts;
MATCH (i:Indicator) RETURN COUNT(i) as indicators;
MATCH (ser:Series) RETURN COUNT(ser) as series_points;

