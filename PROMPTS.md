# DESTA Trade Network — Step-by-Step Prompts

This document records the **sequential prompts** used to build a complete analysis pipeline of the DESTA (Design of Trade Agreements) dataset, starting from a raw CSV and ending with an interactive R Shiny dashboard. Each step builds on the artifacts produced by the previous one.

---

## 📦 Project Artifacts

| File | Produced by | Description |
|---|---|---|
| [`desta_list_of_treaties.csv`](desta_list_of_treaties.csv) | (input) | Raw DESTA treaty dataset |
| [`desta_analysis.R`](desta_analysis.R) | Step 1 | Exploratory data analysis + 6 plots |
| [`plots/`](plots/) | Steps 1 & 3 | PNG outputs (plot1–plot5 from Step 1; plot6 from Step 3) |
| [`network_edges.csv`](network_edges.csv), [`network_nodes.csv`](network_nodes.csv) | Step 2 | Bilateral edge/node lists |
| [`network_diagram.R`](network_diagram.R) | Step 2 | Builds & exports the network graph |
| [`bilateral_trade_network.html`](bilateral_trade_network.html) | Step 2 | Interactive HTML network |
| [`centrality_analysis.R`](centrality_analysis.R) | Step 3 | Degree / closeness / betweenness / eigenvector / PageRank |
| [`network_centrality.csv`](network_centrality.csv) | Step 3 | Centrality scores per country |
| [`app.R`](app.R) | Step 4 | Shiny dashboard combining everything |

---

## Step 1 — Exploratory Analysis of the DESTA Treaty Dataset

**Goal:** Understand the shape of the data and surface candidate dimensions for deeper analysis.

### 🟦 Prompt

> Read the file [`desta_list_of_treaties.csv`](desta_list_of_treaties.csv) , reference the DESTA_FIELD_DESCRIPTIONS.md and perform an exploratory data analysis. Identify the key columns (year, region, entry type, membership type, country participation). Produce the following plots and save them to a `plots/` directory:
>
> 1. **plot1** — Treaties signed per year (line chart)
> 2. **plot2** — Treaties by region (bar chart)
> 3. **plot3** — Distribution of entry types (e.g. `base_treaty`, `accession`, `amendment`)
> 4. **plot4** — Membership type breakdown
> 5. **plot4b** — Top countries by number of *bilateral* treaties
> 6. **plot5** — Stacked bar of regions by decade
>
> Save the full script as [`desta_analysis.R`](desta_analysis.R). Use [`tidyverse`](desta_analysis.R:1) and [`ggplot2`](desta_analysis.R:1). Each plot should be exported as a PNG at 1200×800 px.

### ✅ Expected outputs
- [`desta_analysis.R`](desta_analysis.R)
- [`plots/plot1_treaties_per_year.png`](plots/plot1_treaties_per_year.png)
- [`plots/plot2_treaties_by_region.png`](plots/plot2_treaties_by_region.png)
- [`plots/plot3_entry_type.png`](plots/plot3_entry_type.png)
- [`plots/plot4_membership_type.png`](plots/plot4_membership_type.png)
- [`plots/plot4b_top_bilateral_countries.png`](plots/plot4b_top_bilateral_countries.png)
- [`plots/plot5_region_decade_stacked.png`](plots/plot5_region_decade_stacked.png)

### 🔍 Decision point
After reviewing the plots, **plot4** and **plot4b** reveal that *bilateral* treaties has a small set of countries account for most of them. This motivates a deeper network-style analysis of bilateral relationships.

When counting bilateral treaties per country, the interpretation of "bilateral" matters:

- **If the question is "which countries have signed the most bilateral agreements"** → filter `typememb == 1`, then deduplicate by `base_treaty` before counting, so accessions don't inflate the numbers.
- **If the question is "which countries appear most frequently in bilateral dyads"** → filter `typememb == 1` and count rows directly (each row is already one country-pair appearance).

---

## Step 2 — Build the Bilateral Trade Network

**Goal:** Convert the bilateral subset into a graph (nodes = countries, edges = shared treaties) and visualize it.

### 🟦 Prompt

> Looking at the plots from Step 1, the **bilateral treaties** are the simplest slice of the data that we can use to build a network graph and examine the trade network. Filter [`desta_list_of_treaties.csv`](desta_list_of_treaties.csv) to only `typememb == 1` (both parties are individual states — the true bilateral case). Then:
>
> 1. **Extract nodes** — one row per unique country, with `total_treaties` (count of treaties the country participates in) and `degree` (number of distinct trading partners). Save as [`network_nodes.csv`](network_nodes.csv).
> 2. **Extract edges** — one row per unique country-pair with a `weight` equal to the number of bilateral treaties they share. Save as [`network_edges.csv`](network_edges.csv) with columns `source`, `target`, `weight`.
> 3. **Build a network diagram** using [`igraph`](network_diagram.R:1) for graph construction and [`visNetwork`](network_diagram.R:1) for an interactive HTML rendering.
>    - Node size ∝ `total_treaties`
>    - Edge width ∝ `weight`
>    - Tooltip showing country name, treaty count, and partner count
>    - Physics-enabled force-directed layout
> 4. Export the interactive diagram to [`bilateral_trade_network.html`](bilateral_trade_network.html).
>
> Save the full pipeline as [`network_diagram.R`](network_diagram.R).

### ✅ Expected outputs
- [`network_nodes.csv`](network_nodes.csv) — `country`, `total_treaties`, `degree`
- [`network_edges.csv`](network_edges.csv) — `source`, `target`, `weight`
- [`network_diagram.R`](network_diagram.R)
- [`bilateral_trade_network.html`](bilateral_trade_network.html)

---

## Step 3 — Centrality Analysis (Identify Influential Nodes)

**Goal:** Quantify which countries are most "important" in the bilateral trade network using complementary centrality measures.

### 🟦 Prompt

> Using the [`network_edges.csv`](network_edges.csv) and [`network_nodes.csv`](network_nodes.csv) produced in Step 2, compute the following centrality scores for **every** country in the network using [`igraph`](centrality_analysis.R:1):
>
> | Measure | Captures |
> |---|---|
> | **Degree centrality** | Raw activity / number of partners |
> | **Closeness centrality** | How easily a node reaches all others |
> | **Betweenness centrality** | Brokerage power between sub-communities |
> | **Eigenvector centrality** | Prestige (connected to other influential nodes) |
> | **PageRank** | Random-walk-based prestige with damping |
>
> Then:
>
> 1. Normalize every measure to **[0, 1]**.
> 2. Compute a **composite influence score** as the mean of the five normalized measures.
> 3. Rank countries by composite score and produce a bar plot of the **top 15** ([`plots/plot6_centrality_top15.png`](plots/plot6_centrality_top15.png)).
> 4. Save the full per-country score table as [`network_centrality.csv`](network_centrality.csv).
>
> Save the script as [`centrality_analysis.R`](centrality_analysis.R). Add a short commented section interpreting which countries are *brokers* (high betweenness, lower degree) vs *hubs* (high degree, high eigenvector).

### ✅ Expected outputs
- [`centrality_analysis.R`](centrality_analysis.R)
- [`network_centrality.csv`](network_centrality.csv)
- [`plots/plot6_centrality_top15.png`](plots/plot6_centrality_top15.png)

### 💬 Discussion Points — What Each Centrality Score Reveals

| Measure | What a High Score Means | Trade Network Interpretation |
|---|---|---|
| **Degree centrality** | A country has many direct bilateral treaty partners | Reveals the most *active* treaty signers — countries that have broadly engaged with many partners regardless of who those partners are |
| **Closeness centrality** | A country can reach all others in the network in fewer steps | Identifies countries that are well-positioned to *diffuse* trade norms or respond quickly to new agreements; central to the overall network geography |
| **Betweenness centrality** | A country sits on many shortest paths between other countries | Flags *brokers* — countries that act as bridges between otherwise disconnected regions or blocs; removal of these nodes would fragment the network |
| **Eigenvector centrality** | A country is connected to other well-connected countries | Captures *prestige* — not just how many partners a country has, but how influential those partners are; high scores signal membership in the core of the network |
| **PageRank** | A country is linked to by many important countries, weighted by their importance | Similar to eigenvector centrality but more robust to asymmetries; a high score means a country is trusted and sought-after as a treaty partner by other influential countries |
| **Composite score** | Average of all five normalized measures | A balanced summary of overall network importance, smoothing out the different emphases of individual measures |

#### Broker vs. Hub distinction
- **Hubs** (high degree + high eigenvector): Countries like major economies that sign many treaties with other influential partners — they are deeply embedded in the network core.
- **Brokers** (high betweenness + lower degree): Countries that connect otherwise separate clusters — often regional powers or geographically/politically positioned between blocs. Their influence comes from *position*, not volume.

---

## Step 4 — Combine Everything in an R Shiny Dashboard

**Goal:** Provide a single interactive interface that exposes the network diagram and centrality analyses to a non-technical reader.

### 🟦 Prompt

> Build a single-file R Shiny dashboard ([`app.R`](app.R)) using [`shinydashboard`](app.R:1) that re-uses all artifacts produced so far. The dashboard must contain **four tabs**:
>
> 1. **Overview** — KPI value boxes (country count, edge count, network density, top influencer) plus an "About" panel and a top-10 composite-score bar chart.
> 2. **Centrality Charts** — drop-down to choose the ranking measure + slider for top-N; show two side-by-side [`plotly`](app.R:1) plots: (a) ranked bar for the selected measure, (b) grouped bar of all five normalized measures for the same top-N. Plus a configurable scatter of any two measures with point size ∝ treaty count.
> 3. **Country Profile** — pick a country, show: composite rank, treaty count, partner count, betweenness, and a **radar chart** of its five normalized centrality scores.
> 4. **Data Table** — searchable, sortable [`DT::datatable`](app.R:1) of the full centrality scores with an in-cell data bar on the composite column and a CSV download button.
>
> The sidebar must contain a global slider "Top N countries (by treaties)" that filters the table reactively. Use [`igraph`](app.R:1) to recompute centrality once at startup from [`network_edges.csv`](network_edges.csv) / [`network_nodes.csv`](network_nodes.csv) (do **not** depend on the pre-computed CSV — recompute for freshness).
>
> ### Constraints
> - Defensively coerce all input columns to numeric (the CSVs may contain stringified lists).
> - The `degree` column already exists in [`network_nodes.csv`](network_nodes.csv); rename it to `num_partners` before the join with the centrality tibble so it doesn't collide with [`igraph::degree()`](app.R:1).
> - Namespace centrality calls (`igraph::degree`, `igraph::closeness`, …) to avoid masking by [`dplyr`](app.R:1).
> - Wrap the [`norm01()`](app.R:54) helper so empty / zero-range / non-numeric inputs return zeros gracefully.
> - **If the dashboard is not rendering correctly, try breaking the task into smaller steps**: build and test each tab independently before combining into the final `app.R`.

### ✅ Expected output
- [`app.R`](app.R) — run with `shiny::runApp("app.R")` or click **Run App** in RStudio.

### 🐛 Common pitfall — name collision after `left_join`

If you write:

```r
centrality_df <- tibble(degree = igraph::degree(g_full, normalized = TRUE), ...) %>%
  left_join(nodes_raw, by = "country") %>%       # nodes_raw also has `degree`
  mutate(deg_n = norm01(degree))                 # 💥 ambiguous reference
```

…the join produces `degree.x` / `degree.y`, and the bare `degree` in [`mutate()`](app.R:60) can resolve to the [`igraph::degree`](app.R:52) **function**, triggering:

```
Error in `mutate()`:
ℹ In argument: `deg_n = norm01(degree)`.
Caused by error in `min()`:
! invalid 'type' (list) of argument
```

**Fix:** rename `nodes_raw$degree` → `num_partners` *before* the join (already encoded in the constraints above).

---

## 🚀 Running the Full Pipeline

```bash
# Step 1 — EDA + plots
Rscript desta_analysis.R

# Step 2 — Build the bilateral network
Rscript network_diagram.R

# Step 3 — Compute centrality
Rscript centrality_analysis.R

# Step 4 — Launch the dashboard
Rscript -e 'shiny::runApp("app.R", launch.browser = TRUE)'
```

---

## 🧭 Prompt-Engineering Lessons Learned

1. **Anchor each prompt to artifacts** produced by the previous step — this gives the assistant verifiable inputs and prevents drift.
2. **State the decision rationale explicitly** ("plot4b shows bilateral dominance, therefore…") so the assistant doesn't pick a different rabbit hole.
3. **List columns + dtypes** for intermediate CSVs — saves an entire round of debugging name collisions and coercion errors.
4. **Namespace functions** (e.g. `igraph::degree`) in any prompt that mixes [`tidyverse`](app.R:1) and [`igraph`](app.R:1); the two packages share many verbs.
5. **Encode known pitfalls as constraints** rather than waiting for the error — see the `degree` collision note in Step 4.
6. **Reduce scope when outputs fail to render** — if a dashboard or complex artifact is not working correctly, this may indicate a failure in the model's thought process or inability to use a tool properly. Mitigate by removing non-essential components (e.g. the Network Diagram and trading-partner bar chart were removed from Step 4) and prompting the model to break the task into smaller steps, building and testing each tab independently before combining.
