# ============================================================
# DESTA Bilateral Trade Network — Complete Pipeline
# File: network_diagram.R
# Description: Full pipeline from raw data to interactive network
#              1. Filter to bilateral treaties (typememb == 1)
#              2. Extract nodes and edges
#              3. Build interactive visNetwork diagram
# ============================================================

# ---- 1. Load required packages ----
cat("Loading required packages...\n")
required_pkgs <- c("tidyverse", "visNetwork", "htmlwidgets")
missing_pkgs  <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  cat("Installing missing packages:", paste(missing_pkgs, collapse = ", "), "\n")
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

library(tidyverse)
library(visNetwork)
library(htmlwidgets)

# ---- 2. Read and filter raw data ----
cat("\n=== STEP 1: Loading and filtering data ===\n")
desta <- read_csv("desta_list_of_treaties.csv", show_col_types = FALSE)

cat("Total records in dataset:", nrow(desta), "\n")

# Filter to bilateral treaties only (typememb == 1: both parties are individual states)
bilateral <- desta %>%
  filter(typememb == 1)

cat("Bilateral treaty records (typememb == 1):", nrow(bilateral), "\n")
cat("Year range:", min(bilateral$year, na.rm = TRUE), "-", max(bilateral$year, na.rm = TRUE), "\n")

# ---- 3. Extract NODES ----
cat("\n=== STEP 2: Extracting network nodes ===\n")

# Combine country1 and country2 to get all country participations
country_participation <- bilateral %>%
  pivot_longer(cols = c(country1, country2), 
               names_to = "position", 
               values_to = "country") %>%
  select(country, number)

# Calculate node metrics
nodes <- country_participation %>%
  group_by(country) %>%
  summarise(
    total_treaties = n(),                    # Total treaty participation count
    .groups = "drop"
  )

# Calculate degree (number of distinct trading partners)
# For each country, find all unique partners
# Create a list of country-partner pairs
country_partner_pairs <- bind_rows(
  bilateral %>% select(country = country1, partner = country2),
  bilateral %>% select(country = country2, partner = country1)
) %>%
  distinct()

degree_calc <- country_partner_pairs %>%
  group_by(country) %>%
  summarise(degree = n(), .groups = "drop")

# Join total_treaties and degree
nodes <- nodes %>%
  left_join(degree_calc, by = "country") %>%
  arrange(desc(total_treaties))

cat("Unique countries (nodes):", nrow(nodes), "\n")
cat("Top 10 countries by treaty count:\n")
print(nodes %>% slice_head(n = 10))

# Save nodes
write_csv(nodes, "network_nodes.csv")
cat("✓ Saved: network_nodes.csv\n")

# ---- 4. Extract EDGES ----
cat("\n=== STEP 3: Extracting network edges ===\n")

# For each unique country pair, count the number of bilateral treaties
edges <- bilateral %>%
  mutate(
    # Ensure consistent ordering: alphabetically sort country names
    source = if_else(country1 <= country2, country1, country2),
    target = if_else(country1 <= country2, country2, country1)
  ) %>%
  group_by(source, target) %>%
  summarise(weight = n(), .groups = "drop") %>%
  arrange(desc(weight))

cat("Unique country pairs (edges):", nrow(edges), "\n")
cat("Top 10 most connected pairs:\n")
print(edges %>% slice_head(n = 10))

# Save edges
write_csv(edges, "network_edges.csv")
cat("✓ Saved: network_edges.csv\n")

# ---- 5. Build interactive network visualization ----
cat("\n=== STEP 4: Building interactive network ===\n")

# Filter to top countries for visualization clarity
TOP_N <- 50

top_countries <- nodes %>%
  slice_max(total_treaties, n = TOP_N) %>%
  pull(country)

cat("Filtering to top", TOP_N, "countries for visualization...\n")

edges_filtered <- edges %>%
  filter(source %in% top_countries, target %in% top_countries)

nodes_filtered <- nodes %>%
  filter(country %in% top_countries)

cat("Network size:", nrow(nodes_filtered), "nodes,", nrow(edges_filtered), "edges\n")

# ---- 6. Prepare visNetwork data structures ----

# Nodes for visNetwork
nodes_vn <- nodes_filtered %>%
  mutate(
    id    = country,
    label = country,
    value = total_treaties,           # drives node size
    title = paste0(                   # HTML tooltip
      "<b>", country, "</b><br>",
      "Bilateral treaties: ", total_treaties, "<br>",
      "Distinct partners: ", degree
    ),
    # Color by treaty volume quartile
    group = case_when(
      total_treaties >= quantile(total_treaties, 0.75) ~ "High (top 25%)",
      total_treaties >= quantile(total_treaties, 0.50) ~ "Medium-High",
      total_treaties >= quantile(total_treaties, 0.25) ~ "Medium-Low",
      TRUE                                              ~ "Low (bottom 25%)"
    )
  ) %>%
  select(id, label, value, title, group)

# Edges for visNetwork
edges_vn <- edges_filtered %>%
  mutate(
    from  = source,
    to    = target,
    value = weight,                   # drives edge width
    title = paste0(source, " ↔ ", target, "<br>", 
                   "<b>", weight, "</b> bilateral ", 
                   if_else(weight == 1, "treaty", "treaties"))
  ) %>%
  select(from, to, value, title)

cat("visNetwork data prepared\n")

# ---- 7. Create interactive network ----
cat("Rendering interactive network...\n")

net <- visNetwork(
  nodes = nodes_vn,
  edges = edges_vn,
  width  = "100%",
  height = "900px",
  main   = list(
    text  = "Bilateral Trade Agreement Network",
    style = "font-family:Arial, sans-serif; font-size:24px; font-weight:bold; text-align:center; color:#2c3e50;"
  ),
  submain = list(
    text  = paste0(
      "Top ", TOP_N, " countries by bilateral treaty participation (typememb = 1) | ",
      "Node size ∝ total treaties | Edge width ∝ shared treaties | ",
      "Data: DESTA v2.1 (1948-2021)"
    ),
    style = "font-family:Arial, sans-serif; font-size:13px; color:#7f8c8d; text-align:center; margin-bottom:10px;"
  ),
  footer = list(
    text = "Interactive: hover over nodes/edges for details • drag to rearrange • scroll to zoom • use controls to filter",
    style = "font-family:Arial, sans-serif; font-size:11px; color:#95a5a6; text-align:center; margin-top:10px;"
  )
) %>%
  
  # Node styling by group (color scheme)
  visGroups(groupname = "High (top 25%)",    
            color = list(background = "#e74c3c", border = "#c0392b", highlight = "#c0392b"),
            font = list(color = "white", size = 14, face = "bold")) %>%
  visGroups(groupname = "Medium-High", 
            color = list(background = "#f39c12", border = "#d68910", highlight = "#d68910"),
            font = list(color = "white", size = 13)) %>%
  visGroups(groupname = "Medium-Low",  
            color = list(background = "#3498db", border = "#2980b9", highlight = "#2980b9"),
            font = list(color = "white", size = 12)) %>%
  visGroups(groupname = "Low (bottom 25%)",   
            color = list(background = "#95a5a6", border = "#7f8c8d", highlight = "#7f8c8d"),
            font = list(color = "white", size = 11)) %>%
  
  # Edge styling
  visEdges(
    smooth    = list(enabled = TRUE, type = "continuous", roundness = 0.5),
    color     = list(color = "#bdc3c7", highlight = "#e74c3c", opacity = 0.5),
    scaling   = list(min = 0.5, max = 10),
    selectionWidth = 3
  ) %>%
  
  # Node configuration
  visNodes(
    shape   = "dot",
    scaling = list(min = 15, max = 60),
    font    = list(size = 12, face = "arial", strokeWidth = 2, strokeColor = "#ffffff"),
    shadow  = list(enabled = TRUE, color = "rgba(0,0,0,0.3)", size = 10, x = 2, y = 2),
    borderWidth = 2
  ) %>%
  
  # Physics for force-directed layout
  visPhysics(
    solver            = "barnesHut",
    barnesHut         = list(
      gravitationalConstant = -10000,
      centralGravity = 0.3,
      springLength = 150,
      springConstant = 0.04,
      damping = 0.09,
      avoidOverlap = 0.5
    ),
    stabilization     = list(
      enabled = TRUE, 
      iterations = 300,
      updateInterval = 50
    ),
    minVelocity = 0.75,
    maxVelocity = 30
  ) %>%
  
  # Add legend
  visLegend(
    width = 0.15, 
    position = "right", 
    main = list(text = "Treaty Volume", style = "font-weight:bold; font-size:14px;"),
    useGroups = TRUE,
    ncol = 1
  ) %>%
  
  # Interactive options
  visOptions(
    highlightNearest = list(enabled = TRUE, degree = 1, hover = TRUE, labelOnly = FALSE),
    nodesIdSelection = list(
      enabled = TRUE, 
      main = "Select country:",
      style = "width:200px; padding:5px;"
    ),
    selectedBy = list(
      variable = "group", 
      main = "Filter by tier:",
      style = "width:200px; padding:5px;"
    ),
    collapse = FALSE
  ) %>%
  
  # Navigation and interaction
  visInteraction(
    navigationButtons = TRUE,
    tooltipDelay      = 100,
    tooltipStyle      = "position:fixed; visibility:hidden; padding:8px; font-family:arial; font-size:12px; background-color:rgba(0,0,0,0.85); color:white; border-radius:4px; max-width:300px;",
    zoomView          = TRUE,
    dragView          = TRUE,
    hover             = TRUE,
    keyboard          = TRUE,
    multiselect       = TRUE,
    hideEdgesOnDrag   = FALSE
  ) %>%
  
  # Event handling for better UX
  visEvents(
    type = "once",
    stabilized = "function() {
      this.fit({animation: {duration: 1000, easingFunction: 'easeInOutQuad'}});
    }"
  )

# ---- 8. Save interactive HTML ----
output_file <- "bilateral_trade_network.html"
saveWidget(net, output_file, selfcontained = TRUE)

cat("\n=== SUCCESS ===\n")
cat("✓ Interactive network saved to:", output_file, "\n")
cat("✓ Open in any web browser to explore the network\n")

# ---- 9. Summary statistics ----
cat("\n=== NETWORK SUMMARY ===\n")
cat("Nodes (countries):", nrow(nodes_vn), "\n")
cat("Edges (country pairs):", nrow(edges_vn), "\n")
cat("Average treaties per country:", round(mean(nodes_filtered$total_treaties), 1), "\n")
cat("Most connected country:", nodes_filtered$country[1], 
    "with", nodes_filtered$total_treaties[1], "treaties\n")
cat("Strongest partnership:", edges_filtered$source[1], "↔", edges_filtered$target[1],
    "with", edges_filtered$weight[1], "bilateral treaties\n")

cat("\n=== Pipeline complete! ===\n")
cat("Files generated:\n")
cat("  1. network_nodes.csv (", nrow(nodes), "countries )\n")
cat("  2. network_edges.csv (", nrow(edges), "pairs )\n")
cat("  3. bilateral_trade_network.html (interactive visualization)\n")
