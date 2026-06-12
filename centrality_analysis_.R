# ============================================================
# DESTA Trade Network — Centrality Analysis
# File: centrality_analysis.R
# Description: Identifies the most influential countries in the
#              trade agreement network (all treaty types) using five
#              complementary centrality measures:
#                - Degree        (activity / direct connections)
#                - Closeness     (reach / average distance to others)
#                - Betweenness   (brokerage / bridging role)
#                - Eigenvector   (prestige / connected to important nodes)
#                - PageRank      (prestige / random-walk importance)
# ============================================================

# ---- 1. Packages ----
required_pkgs <- c("tidyverse", "igraph", "scales")
missing_pkgs  <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing_pkgs) > 0) install.packages(missing_pkgs)

suppressPackageStartupMessages({
  library(tidyverse)
  library(igraph)
  library(scales)
})

# ---- 2. Load network data ----
if (!file.exists("network_edges.csv") || !file.exists("network_nodes.csv")) {
  stop("Run desta_analysis.R first to generate network_edges.csv and network_nodes.csv.")
}

edges_raw <- read_csv("network_edges.csv", show_col_types = FALSE)
nodes_raw <- read_csv("network_nodes.csv", show_col_types = FALSE)

cat("Network loaded:", nrow(nodes_raw), "nodes,", nrow(edges_raw), "edges\n\n")

# ---- 3. Build igraph object ----
# Undirected, weighted graph (weight = number of treaties between pair, all types)
g <- graph_from_data_frame(
  d        = edges_raw %>% rename(from = source, to = target),
  directed = FALSE,
  vertices = nodes_raw %>% select(country, total_treaties, degree)
)

# For distance-based measures, treat each edge as unit length (topological)
# (Using weights as costs would penalise heavily-tied pairs, which is the
#  opposite of what we want for trade influence.)

# ---- 4. Compute centrality measures ----
cat("Computing centrality measures...\n")

cent <- tibble(
  country     = V(g)$name,
  degree      = degree(g, normalized = TRUE),                     # activity
  closeness   = closeness(g, normalized = TRUE),                  # reach
  betweenness = betweenness(g, weights = NA, normalized = TRUE),  # brokerage
  eigenvector = eigen_centrality(g, weights = E(g)$weight)$vector,# prestige
  pagerank    = page_rank(g, weights = E(g)$weight)$vector        # prestige
)

# ---- 5. Build composite influence score ----
# Rank each measure (1 = best), then average the ranks; lower = more influential.
# Also produce a 0-1 normalised score per measure for readability.
norm01 <- function(x) (x - min(x, na.rm = TRUE)) /
                      (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))

cent_scored <- cent %>%
  mutate(
    deg_n   = norm01(degree),
    clo_n   = norm01(closeness),
    btw_n   = norm01(betweenness),
    eig_n   = norm01(eigenvector),
    pr_n    = norm01(pagerank),
    composite_score = (deg_n + clo_n + btw_n + eig_n + pr_n) / 5
  ) %>%
  arrange(desc(composite_score))

# ---- 6. Top-10 tables per measure ----
top_n_table <- function(df, col, n = 10) {
  df %>% arrange(desc(.data[[col]])) %>%
    slice_head(n = n) %>%
    transmute(rank = row_number(),
              country,
              score = round(.data[[col]], 4))
}

cat("\n========================================================\n")
cat("TOP 10 — DEGREE CENTRALITY  (activity / direct partners)\n")
cat("========================================================\n")
print(top_n_table(cent, "degree"))

cat("\n========================================================\n")
cat("TOP 10 — CLOSENESS CENTRALITY  (reach across the network)\n")
cat("========================================================\n")
print(top_n_table(cent, "closeness"))

cat("\n========================================================\n")
cat("TOP 10 — BETWEENNESS CENTRALITY  (brokerage / bridges)\n")
cat("========================================================\n")
print(top_n_table(cent, "betweenness"))

cat("\n========================================================\n")
cat("TOP 10 — EIGENVECTOR CENTRALITY  (prestige)\n")
cat("========================================================\n")
print(top_n_table(cent, "eigenvector"))

cat("\n========================================================\n")
cat("TOP 10 — PAGERANK  (random-walk prestige)\n")
cat("========================================================\n")
print(top_n_table(cent, "pagerank"))

cat("\n========================================================\n")
cat("TOP 15 — COMPOSITE INFLUENCE  (mean of normalised scores)\n")
cat("========================================================\n")
print(
  cent_scored %>%
    slice_head(n = 15) %>%
    transmute(
      rank        = row_number(),
      country,
      degree      = round(deg_n, 3),
      closeness   = round(clo_n, 3),
      betweenness = round(btw_n, 3),
      eigenvector = round(eig_n, 3),
      pagerank    = round(pr_n, 3),
      composite   = round(composite_score, 3)
    )
)

# ---- 7. Save full centrality table ----
write_csv(cent_scored, "network_centrality.csv")
cat("\nFull centrality table saved to: network_centrality.csv\n")

# ---- 8. Visualisation: top-15 composite, with measure breakdown ----
top15 <- cent_scored %>% slice_head(n = 15)

plot_df <- top15 %>%
  select(country, Degree = deg_n, Closeness = clo_n,
         Betweenness = btw_n, Eigenvector = eig_n, PageRank = pr_n) %>%
  pivot_longer(-country, names_to = "measure", values_to = "score") %>%
  mutate(country = factor(country, levels = rev(top15$country)),
         measure = factor(measure,
                          levels = c("Degree", "Closeness", "Betweenness",
                                     "Eigenvector", "PageRank")))

p_cent <- ggplot(plot_df, aes(x = score, y = country, fill = measure)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.75, alpha = 0.9) +
  scale_fill_brewer(palette = "Set1") +
  scale_x_continuous(labels = scales::number_format(accuracy = 0.01),
                     expand = expansion(mult = c(0, 0.05))) +
  labs(
    title    = "Most Influential Countries in the DESTA Trade Network",
    subtitle = "Top 15 by composite influence (mean of 5 normalised centrality measures)",
    x        = "Normalised centrality score (0–1)",
    y        = NULL,
    fill     = "Measure",
    caption  = "Degree = activity | Closeness = reach | Betweenness = brokerage | Eigenvector & PageRank = prestige"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5, colour = "grey40"),
    plot.caption  = element_text(hjust = 0, colour = "grey30", size = 9),
    legend.position = "top",
    panel.grid.minor = element_blank()
  )

dir.create("plots", showWarnings = FALSE)
ggsave("plots/plot6_centrality_top15.png", p_cent, width = 11, height = 8, dpi = 150)
cat("Plot saved to: plots/plot6_centrality_top15.png\n")

print(p_cent)

# ---- 9. Detailed interpretation of the centrality scores ----
# This section prints a plain-language guide to what each score means,
# how it is computed, how to read it, and an automatic readout of what
# the actual results say about this particular network.

cat("\n\n")
cat("================================================================\n")
cat("           INTERPRETATION OF THE CENTRALITY SCORES               \n")
cat("================================================================\n")

cat("
Each country is scored on five complementary measures of 'importance'
in the DESTA trade-agreement network (all treaty types). Because each
measure captures a *different* notion of influence, a country can score
high on one and low on another — that contrast is itself informative.

All scores below are normalised to the 0–1 range:
   0  = least central country in the network
   1  = most central country in the network

----------------------------------------------------------------
1) DEGREE CENTRALITY — 'How many partners do you have?'
----------------------------------------------------------------
  Definition : Number of distinct trade partners (direct edges),
               divided by the maximum possible (n - 1).
  Interprets : Sheer ACTIVITY / OPENNESS in signing trade agreements.
  High score : The country has signed agreements with a large share
               of all other countries in the network.
  Low  score : Few direct trade partners — a peripheral signer.
  Caveat     : Counts partners equally; a treaty with Andorra is
               worth as much as a treaty with the EU.

----------------------------------------------------------------
2) CLOSENESS CENTRALITY — 'How quickly can you reach everyone?'
----------------------------------------------------------------
  Definition : Inverse of the mean shortest-path distance from the
               country to all others in the network.
  Interprets : REACH. A high-closeness country is, on average, only
               a few 'hops' away from every other country.
  High score : Well-positioned to diffuse trade norms, standards, or
               shocks rapidly across the system.
  Low  score : Sits on the periphery; information / influence has to
               travel through many intermediaries to reach it.
  Caveat     : Tends to compress into a narrow range in dense
               networks (most countries are 2–3 hops apart).

----------------------------------------------------------------
3) BETWEENNESS CENTRALITY — 'Are you a bridge?'
----------------------------------------------------------------
  Definition : Share of all shortest paths between other pairs of
               countries that pass through this country.
  Interprets : BROKERAGE / GATEKEEPING power. Bridges connect
               otherwise-separated regional clusters.
  High score : Removing this country would fragment the network or
               lengthen many trade-diplomacy paths. Classic 'hub'
               or 'connector' between regions.
  Low  score : Sits inside a cluster; its removal would not split
               the network because alternative paths exist.
  Caveat     : Very sensitive to a few key links; can spike for
               otherwise small countries that happen to bridge
               two regions.

----------------------------------------------------------------
4) EIGENVECTOR CENTRALITY — 'Are your partners important?'
----------------------------------------------------------------
  Definition : A country's score is proportional to the sum of the
               scores of its neighbours (recursive definition).
  Interprets : PRESTIGE. Being linked to many central countries
               matters more than being linked to many peripheral
               ones.
  High score : Embedded in the 'core club' of major traders.
  Low  score : Either few partners, or partners who are themselves
               peripheral.
  Caveat     : Can concentrate almost all mass on one tightly
               connected cluster.

----------------------------------------------------------------
5) PAGERANK — 'Random-walk prestige'
----------------------------------------------------------------
  Definition : Stationary probability of a random walker (with
               occasional teleports) being at this country.
  Interprets : A more robust cousin of eigenvector centrality;
               handles weakly-connected components better and
               down-weights links from very high-degree neighbours.
  High score : Frequently 'visited' by trade-influence flows.
  Low  score : Rarely reached by such flows.

----------------------------------------------------------------
COMPOSITE INFLUENCE SCORE
----------------------------------------------------------------
  Definition : Mean of the five normalised measures above.
  Interprets : Overall importance, balancing activity, reach,
               brokerage, and prestige. A country only scores high
               here if it is strong on *most* dimensions.
")

# ---- 9a. Automatic readout of this network's results ----
cat("----------------------------------------------------------------\n")
cat("WHAT THE NUMBERS SAY ABOUT THIS NETWORK\n")
cat("----------------------------------------------------------------\n")

top_by <- function(col, n = 3) {
  cent_scored %>% arrange(desc(.data[[col]])) %>%
    slice_head(n = n) %>% pull(country) %>% paste(collapse = ", ")
}

cat(sprintf("  Most active signers (degree)        : %s\n", top_by("degree")))
cat(sprintf("  Best-positioned for reach (closeness): %s\n", top_by("closeness")))
cat(sprintf("  Top brokers / bridges (betweenness) : %s\n", top_by("betweenness")))
cat(sprintf("  Most prestigious (eigenvector)      : %s\n", top_by("eigenvector")))
cat(sprintf("  Top PageRank countries              : %s\n", top_by("pagerank")))
cat(sprintf("  Overall most influential (composite): %s\n",
            top_by("composite_score", 5)))

# Detect "specialists": countries that rank in the top-10 on exactly one
# measure. These are interesting because their role is one-dimensional.
ranks <- cent_scored %>%
  transmute(country,
            r_deg = rank(-degree,      ties.method = "min"),
            r_clo = rank(-closeness,   ties.method = "min"),
            r_btw = rank(-betweenness, ties.method = "min"),
            r_eig = rank(-eigenvector, ties.method = "min"),
            r_pr  = rank(-pagerank,    ties.method = "min")) %>%
  mutate(top10_count = rowSums(across(starts_with("r_"), ~ .x <= 10)))

specialists <- ranks %>%
  filter(top10_count == 1) %>%
  rowwise() %>%
  mutate(specialty = c("Degree","Closeness","Betweenness",
                       "Eigenvector","PageRank")[
    which.min(c(r_deg, r_clo, r_btw, r_eig, r_pr))]) %>%
  ungroup() %>%
  select(country, specialty)

if (nrow(specialists) > 0) {
  cat("\n  Single-dimension specialists (top-10 on only ONE measure):\n")
  for (i in seq_len(nrow(specialists))) {
    cat(sprintf("    - %-30s (strong on %s only)\n",
                specialists$country[i], specialists$specialty[i]))
  }
  cat("    -> These countries play a NARROW but distinctive role:\n")
  cat("       e.g. a pure 'broker' bridges regions without having many\n")
  cat("       partners, while a pure 'degree' country signs widely but\n")
  cat("       with less-central partners.\n")
}

# All-rounders: top-10 on 4 or 5 measures
allrounders <- ranks %>% filter(top10_count >= 4) %>% pull(country)
if (length(allrounders) > 0) {
  cat("\n  All-rounders (top-10 on at least 4 of 5 measures):\n")
  cat("    ", paste(allrounders, collapse = ", "), "\n", sep = "")
  cat("    -> These are the genuine hubs of the trade agreement system:\n")
  cat("       active, well-connected, prestigious, AND structurally\n")
  cat("       important as bridges.\n")
}

cat("\n----------------------------------------------------------------\n")
cat("HOW TO READ THE BAR CHART (plots/plot6_centrality_top15.png)\n")
cat("----------------------------------------------------------------\n")
cat("  - Each country has 5 coloured bars, one per measure.\n")
cat("  - A 'tall and even' profile (all bars long)  => true hub.\n")
cat("  - A 'spiky' profile (one bar dominates)      => specialist\n")
cat("    role (e.g. broker-only or activity-only).\n")
cat("  - Compare Degree vs Eigenvector: a country high on degree but\n")
cat("    low on eigenvector signs MANY but with peripheral partners.\n")
cat("  - Compare Betweenness vs the rest: high betweenness with\n")
cat("    moderate degree signals a STRUCTURAL BRIDGE between regions.\n")
cat("================================================================\n")
