# ============================================================
# DESTA Network Centrality Analysis
# File: centrality_analysis.R
# Description: Compute multiple centrality measures for the 
#              bilateral trade network and identify hubs vs brokers
# ============================================================

# ---- 1. Load required packages ----
cat("Loading required packages...\n")
required_pkgs <- c("tidyverse", "igraph", "ggplot2", "scales")
missing_pkgs  <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]

if (length(missing_pkgs) > 0) {
  cat("Installing missing packages:", paste(missing_pkgs, collapse = ", "), "\n")
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

library(tidyverse)
library(igraph)
library(ggplot2)
library(scales)

# ---- 2. Load network data ----
cat("\n=== STEP 1: Loading network data ===\n")

if (!file.exists("network_edges.csv") || !file.exists("network_nodes.csv")) {
  stop("Error: network_edges.csv or network_nodes.csv not found.\n",
       "Please run network_diagram.R first to generate these files.")
}

edges <- read_csv("network_edges.csv", show_col_types = FALSE)
nodes <- read_csv("network_nodes.csv", show_col_types = FALSE)

cat("Loaded", nrow(nodes), "nodes and", nrow(edges), "edges\n")

# ---- 3. Build igraph network ----
cat("\n=== STEP 2: Building igraph network ===\n")

# Create igraph object from edges (undirected network)
g <- graph_from_data_frame(
  d = edges %>% select(source, target, weight),
  directed = FALSE,
  vertices = nodes %>% select(country, total_treaties, degree)
)

cat("Network built:\n")
cat("  Vertices:", vcount(g), "\n")
cat("  Edges:", ecount(g), "\n")
cat("  Connected:", is_connected(g), "\n")

# ---- 4. Compute centrality measures ----
cat("\n=== STEP 3: Computing centrality measures ===\n")

# Extract vertex names for the data frame
vertex_names <- V(g)$name

# Compute five centrality measures
cat("  Computing degree centrality...\n")
degree_cent <- degree(g)

cat("  Computing closeness centrality...\n")
closeness_cent <- closeness(g, normalized = FALSE)

cat("  Computing betweenness centrality...\n")
betweenness_cent <- betweenness(g, normalized = FALSE)

cat("  Computing eigenvector centrality...\n")
eigenvector_cent <- eigen_centrality(g, scale = TRUE)$vector

cat("  Computing PageRank...\n")
pagerank_cent <- page_rank(g)$vector

# ---- 5. Create centrality data frame ----
centrality_df <- tibble(
  country = vertex_names,
  degree_raw = degree_cent,
  closeness_raw = closeness_cent,
  betweenness_raw = betweenness_cent,
  eigenvector_raw = eigenvector_cent,
  pagerank_raw = pagerank_cent
)

# ---- 6. Normalize all measures to [0, 1] ----
cat("\n=== STEP 4: Normalizing centrality measures ===\n")

normalize_to_01 <- function(x) {
  if (max(x, na.rm = TRUE) == min(x, na.rm = TRUE)) return(rep(0.5, length(x)))
  (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

centrality_df <- centrality_df %>%
  mutate(
    degree_norm = normalize_to_01(degree_raw),
    closeness_norm = normalize_to_01(closeness_raw),
    betweenness_norm = normalize_to_01(betweenness_raw),
    eigenvector_norm = normalize_to_01(eigenvector_raw),
    pagerank_norm = normalize_to_01(pagerank_raw)
  )

# ---- 7. Compute composite influence score ----
cat("=== STEP 5: Computing composite influence score ===\n")

centrality_df <- centrality_df %>%
  mutate(
    composite_score = (degree_norm + closeness_norm + betweenness_norm + 
                       eigenvector_norm + pagerank_norm) / 5
  ) %>%
  arrange(desc(composite_score))

# Add rank
centrality_df <- centrality_df %>%
  mutate(rank = row_number())

cat("Top 10 countries by composite influence:\n")
print(centrality_df %>% 
        select(rank, country, composite_score, degree_raw, betweenness_norm) %>%
        slice_head(n = 10))

# ---- 8. Save full centrality table ----
write_csv(centrality_df, "network_centrality.csv")
cat("\n✓ Saved: network_centrality.csv\n")

# ---- 9. Create visualization of top 15 ----
cat("\n=== STEP 6: Creating visualization ===\n")

# Create plots directory if needed
if (!dir.exists("plots")) {
  dir.create("plots")
}

top_15 <- centrality_df %>%
  slice_head(n = 15)

plot6 <- ggplot(top_15, aes(x = reorder(country, composite_score), 
                             y = composite_score, 
                             fill = composite_score)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.3f", composite_score)), 
            hjust = -0.1, size = 3.5, fontface = "bold") +
  coord_flip() +
  labs(
    title = "Top 15 Countries by Network Centrality",
    subtitle = "Composite influence score: mean of 5 normalized centrality measures",
    x = "Country",
    y = "Composite Influence Score",
    caption = "Measures: Degree, Closeness, Betweenness, Eigenvector, PageRank | Source: DESTA v2.1"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40", size = 11),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(color = "gray50", size = 9, hjust = 0),
    axis.text.y = element_text(size = 11)
  ) +
  scale_fill_gradient(low = "#3498DB", high = "#E74C3C") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)), 
                     breaks = seq(0, 1, 0.1))

ggsave("plots/plot6_centrality_top15.png", plot6, 
       width = 12, height = 8, dpi = 100, bg = "white")

cat("✓ Saved: plots/plot6_centrality_top15.png\n")

# ---- 10. Identify network roles: Hubs vs Brokers ----
cat("\n=== STEP 7: Identifying network roles ===\n")

# Classify countries by their centrality profile
centrality_df <- centrality_df %>%
  mutate(
    # Hubs: High degree + high eigenvector (well-connected to other well-connected nodes)
    is_hub = degree_norm > 0.7 & eigenvector_norm > 0.7,
    
    # Brokers: High betweenness but not necessarily high degree 
    # (connect different communities but may not have many direct connections)
    is_broker = betweenness_norm > 0.7 & degree_norm < 0.7,
    
    # Classify role
    role = case_when(
      is_hub & is_broker ~ "Hub & Broker",
      is_hub ~ "Hub",
      is_broker ~ "Broker",
      composite_score > 0.5 ~ "Influential",
      TRUE ~ "Peripheral"
    )
  )

# Update the saved CSV with role classification
write_csv(centrality_df, "network_centrality.csv")

cat("\n=== NETWORK ROLE INTERPRETATION ===\n\n")

# Hubs: Countries with high degree AND high eigenvector centrality
hubs <- centrality_df %>%
  filter(role %in% c("Hub", "Hub & Broker")) %>%
  arrange(desc(eigenvector_norm))

cat("🌟 HUBS (High degree + high eigenvector centrality):\n")
cat("   These countries are densely connected AND connected to other influential nations.\n")
cat("   They are at the center of the trade network and wield significant influence.\n\n")
if (nrow(hubs) > 0) {
  cat("   Top Hubs:\n")
  for (i in 1:min(5, nrow(hubs))) {
    cat(sprintf("   %d. %s (degree: %d, eigenvector: %.3f, composite: %.3f)\n",
                i, hubs$country[i], hubs$degree_raw[i], 
                hubs$eigenvector_raw[i], hubs$composite_score[i]))
  }
} else {
  cat("   None identified in current network.\n")
}

# Brokers: Countries with high betweenness but lower degree
brokers <- centrality_df %>%
  filter(role == "Broker") %>%
  arrange(desc(betweenness_norm))

cat("\n🔗 BROKERS (High betweenness + lower degree):\n")
cat("   These countries bridge different communities in the trade network.\n")
cat("   They may not have the most connections, but they control key pathways\n")
cat("   between different regional or economic blocs.\n\n")
if (nrow(brokers) > 0) {
  cat("   Top Brokers:\n")
  for (i in 1:min(5, nrow(brokers))) {
    cat(sprintf("   %d. %s (degree: %d, betweenness: %.0f, composite: %.3f)\n",
                i, brokers$country[i], brokers$degree_raw[i], 
                brokers$betweenness_raw[i], brokers$composite_score[i]))
  }
} else {
  cat("   None identified with current thresholds.\n")
}

# Countries that are both
both <- centrality_df %>%
  filter(role == "Hub & Broker") %>%
  arrange(desc(composite_score))

cat("\n⭐ HUB & BROKER (High in both dimensions):\n")
cat("   These are the most powerful nodes: densely connected AND bridge communities.\n\n")
if (nrow(both) > 0) {
  cat("   Countries:\n")
  for (i in 1:min(5, nrow(both))) {
    cat(sprintf("   %d. %s (degree: %d, betweenness: %.0f, eigenvector: %.3f)\n",
                i, both$country[i], both$degree_raw[i], 
                both$betweenness_raw[i], both$eigenvector_raw[i]))
  }
} else {
  cat("   None identified in current network.\n")
}

# Summary statistics by role
cat("\n=== ROLE DISTRIBUTION ===\n")
role_summary <- centrality_df %>%
  count(role, sort = TRUE)
print(role_summary)

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("Files generated:\n")
cat("  1. network_centrality.csv (full centrality scores for all countries)\n")
cat("  2. plots/plot6_centrality_top15.png (visualization of top 15 countries)\n")
cat("\nKey Insights:\n")
cat("  - Degree: Measures raw activity (number of trading partners)\n")
cat("  - Closeness: How easily a node reaches all others in the network\n")
cat("  - Betweenness: Brokerage power (control of paths between communities)\n")
cat("  - Eigenvector: Prestige (connected to other influential nodes)\n")
cat("  - PageRank: Random-walk-based importance with damping\n")
cat("  - Composite: Average of all normalized measures\n")
cat("\nInterpretation:\n")
cat("  - Hubs = High degree + high eigenvector → Central, influential players\n")
cat("  - Brokers = High betweenness + lower degree → Bridge different communities\n")
cat("  - Hub & Broker = Both → Most powerful positions in the network\n")
