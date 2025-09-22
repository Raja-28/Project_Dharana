# 📊 Dharana Project

Dharana is a data-driven analytics platform that combines **Neo4j (graph database)**, **Rust (WASM compute)**, and a **React dashboard** to provide insights into key socio-economic indicators such as literacy and employment.

---

## 🚀 Features

* **Backend (Phase 1 & 2)**

  * Express + TypeScript API
  * Neo4j integration for storing & querying indicator data
  * Rust → WASM module for high-performance calculations:

    * Mean
    * Percentage Change
    * Slope (trend)
    * Pearson Correlation

* **Frontend (Phase 3 & 4)**

  * React + Vite + TailwindCSS dashboard
  * Input questions in natural language (e.g. *“How did literacy change last decade?”*)
  * Visualization with Recharts line charts
  * Summary cards with computed insights
  * Compare multiple indicators with correlation analysis

* **Data Model**

  * `Indicator` nodes (e.g., literacy, employment)
  * `Series` nodes (year → value)
  * `Geo` nodes (countries, regions)
  * Relationships: `HAS_SERIES`, `MEASURED_IN`

---

## 🛠️ Tech Stack

* **Database**: Neo4j
* **Backend**: Node.js, Express, TypeScript
* **Compute**: Rust (compiled to WebAssembly)
* **Frontend**: React, Vite, TailwindCSS, Recharts
* **Deployment**: Docker (API + Neo4j), Vercel/Netlify (Frontend)

---

## 📦 Setup Instructions

### 1. Clone & Install

```bash
git clone <repo-url>
cd dharana_poc_light
```

### 2. Backend Setup

```bash
cd services/api
npm install
npm run dev
```

Runs API on **[http://localhost:3000](http://localhost:3000)**

### 3. Neo4j Setup

* Install and start Neo4j Desktop / Docker container
* Load seed data into the graph:

```cypher
MERGE (india:Geo {code:'IN', name:'India'})
MERGE (lit:Indicator {id:'rural_literacy_rate', name:'Rural Literacy Rate'})
MERGE (emp:Indicator {id:'employment_rate', name:'Employment Rate'})
WITH lit, emp, india
UNWIND range(2014, 2024) AS y
MERGE (s1:Series {year:y, indicator:'rural_literacy_rate'})
  SET s1.value = 60 + (y-2014)*0.8
MERGE (s2:Series {year:y, indicator:'employment_rate'})
  SET s2.value = 40 + (y-2014)*0.3
MERGE (lit)-[:HAS_SERIES]->(s1)
MERGE (emp)-[:HAS_SERIES]->(s2)
MERGE (s1)-[:MEASURED_IN]->(india)
MERGE (s2)-[:MEASURED_IN]->(india);
```

### 4. Rust WASM Setup

```bash
cd services/compute/rust-wasm
wasm-pack build --release --target nodejs --out-dir pkg
npm install ./pkg
```

### 5. Frontend Setup

```bash
cd dashboard
npm install
npm run dev
```

Runs frontend on **[http://localhost:5173](http://localhost:5173)**

---

## 🔑 API Endpoints

### Health Check

```bash
GET /health
```

Response:

```json
{ "ok": true, "wasmReady": true }
```

### Ask Question

```bash
POST /ask
{ "question": "How did literacy change last decade?" }
```

Response:

```json
{
  "question": "How did literacy change last decade?",
  "indicators": ["rural_literacy_rate"],
  "summary": {
    "rural_literacy_rate": {
      "mean": 64,
      "pct_change": 13.3,
      "slope": 0.8
    }
  },
  "series": { ... }
}
```

### Compare Indicators

```bash
POST /compare
{ "indicators": ["rural_literacy_rate", "employment_rate"] }
```

Response:

```json
{
  "indicators": ["rural_literacy_rate", "employment_rate"],
  "correlation": 0.98
}
```

---

## 📊 Example Output

* Literacy improved steadily from 2014 → 2024 with a slope of `0.8`
* Employment grew with a smaller slope (`0.3`) but still positive
* Correlation between literacy & employment ≈ `0.98` (strong positive)

---

## 📌 Roadmap

* [x] Phase 1 – Core API + Neo4j
* [x] Phase 2 – Rust WASM compute integration
* [x] Phase 3 – Dashboard with charts
* [x] Phase 4 – Compare & correlation
* [x] Phase 5 – Deployment (Docker + Vercel/Netlify)
* [x] Phase 6 – NLP enhancements for better question parsing
* [x] Phase 7 – Regional drilldowns & advanced visualizations

---

## 👥 Contributors

* **Karthick Rajav** – Lead Developer
* **Assistant (AI)** – Architecture, code scaffolding, and guidance

---

## 📜 License

MIT License
