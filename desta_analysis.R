# DESTA Trade Agreements - Exploratory Data Analysis
# Author: Generated Analysis Script
# Date: 2026-06-11
# Description: Comprehensive EDA of DESTA treaty data with visualizations

# Load required libraries
library(tidyverse)
library(ggplot2)
library(scales)

# Create plots directory if it doesn't exist
if (!dir.exists("plots")) {
  dir.create("plots")
}

# Read the data
cat("Loading data...\n")
desta <- read_csv("desta_list_of_treaties.csv", show_col_types = FALSE)

# Display basic information
cat("\n=== DATASET OVERVIEW ===\n")
cat("Total records:", nrow(desta), "\n")
cat("Total columns:", ncol(desta), "\n")
cat("Year range:", min(desta$year, na.rm = TRUE), "-", max(desta$year, na.rm = TRUE), "\n\n")

# Summary of key columns
cat("=== KEY COLUMN SUMMARIES ===\n")
cat("\nEntry Types:\n")
print(table(desta$entry_type))

cat("\nRegions:\n")
print(table(desta$regioncon))

cat("\nMembership Types:\n")
print(table(desta$typememb))

cat("\n=== STARTING PLOT GENERATION ===\n\n")

# ============================================================================
# PLOT 1: Treaties signed per year (line chart)
# ============================================================================
cat("Generating Plot 1: Treaties signed per year...\n")

treaties_per_year <- desta %>%
  filter(!is.na(year)) %>%
  group_by(year) %>%
  summarise(count = n(), .groups = "drop")

plot1 <- ggplot(treaties_per_year, aes(x = year, y = count)) +
  geom_line(color = "#2C3E50", size = 1.2) +
  geom_point(color = "#E74C3C", size = 2, alpha = 0.6) +
  labs(
    title = "Trade Treaty Records Signed per Year",
    subtitle = "DESTA Dataset: 1948-2021",
    x = "Year",
    y = "Number of Treaty Records",
    caption = "Source: DESTA v2.1"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(color = "gray50", size = 9)
  ) +
  scale_x_continuous(breaks = seq(1950, 2020, 10))

ggsave("plots/plot1_treaties_per_year.png", plot1, 
       width = 12, height = 8, dpi = 100, bg = "white")

# ============================================================================
# PLOT 2: Treaties by region (bar chart)
# ============================================================================
cat("Generating Plot 2: Treaties by region...\n")

treaties_by_region <- desta %>%
  filter(!is.na(regioncon)) %>%
  group_by(regioncon) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count))

plot2 <- ggplot(treaties_by_region, aes(x = reorder(regioncon, count), y = count, fill = regioncon)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = comma(count)), hjust = -0.2, size = 4) +
  coord_flip() +
  labs(
    title = "Trade Treaty Records by Region",
    subtitle = "Regional distribution of treaty country-pairs",
    x = "Region",
    y = "Number of Treaty Records",
    caption = "Source: DESTA v2.1"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(color = "gray50", size = 9)
  ) +
  scale_fill_brewer(palette = "Set2") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15)))

ggsave("plots/plot2_treaties_by_region.png", plot2, 
       width = 12, height = 8, dpi = 100, bg = "white")

# ============================================================================
# PLOT 3: Distribution of entry types
# ============================================================================
cat("Generating Plot 3: Distribution of entry types...\n")

entry_type_dist <- desta %>%
  filter(!is.na(entry_type)) %>%
  group_by(entry_type) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(
    percentage = count / sum(count) * 100,
    label = paste0(comma(count), "\n(", round(percentage, 1), "%)")
  )

plot3 <- ggplot(entry_type_dist, aes(x = reorder(entry_type, -count), y = count, fill = entry_type)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = label), vjust = -0.5, size = 4.5, fontface = "bold") +
  labs(
    title = "Distribution of Entry Types",
    subtitle = "Base treaties, accessions, and amendments",
    x = "Entry Type",
    y = "Number of Records",
    caption = "Source: DESTA v2.1"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(color = "gray50", size = 9)
  ) +
  scale_fill_manual(values = c("base_treaty" = "#3498DB", 
                                 "accession" = "#2ECC71", 
                                 "amendment" = "#F39C12")) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15)))

ggsave("plots/plot3_entry_types.png", plot3, 
       width = 12, height = 8, dpi = 100, bg = "white")

# ============================================================================
# PLOT 4: Membership type breakdown
# ============================================================================
cat("Generating Plot 4: Membership type breakdown...\n")

# Create descriptive labels for membership types
membership_labels <- c(
  "1" = "Both individual states",
  "2" = "State group + individual",
  "3" = "Both state groups",
  "4" = "Customs union + individual",
  "5" = "Customs union + state group",
  "6" = "Both customs unions"
)

membership_dist <- desta %>%
  filter(!is.na(typememb)) %>%
  mutate(typememb_label = membership_labels[as.character(typememb)]) %>%
  group_by(typememb, typememb_label) %>%
  summarise(count = n(), .groups = "drop") %>%
  mutate(
    percentage = count / sum(count) * 100,
    label = paste0(comma(count), "\n(", round(percentage, 1), "%)")
  )

plot4 <- ggplot(membership_dist, aes(x = reorder(typememb_label, -count), y = count, fill = as.factor(typememb))) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = label), vjust = -0.5, size = 3.5, fontface = "bold") +
  labs(
    title = "Membership Type Distribution",
    subtitle = "Classification of treaty party structures",
    x = "Membership Type",
    y = "Number of Records",
    caption = "Source: DESTA v2.1"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    plot.caption = element_text(color = "gray50", size = 9)
  ) +
  scale_fill_brewer(palette = "Set3") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15)))

ggsave("plots/plot4_membership_types.png", plot4, 
       width = 12, height = 8, dpi = 100, bg = "white")

# ============================================================================
# PLOT 4B: Top countries by number of bilateral treaties
# ============================================================================
cat("Generating Plot 4B: Top countries by bilateral treaties...\n")

# Count participation for each country (combining country1 and country2)
country_participation <- desta %>%
  filter(typememb == 1) %>%  # Type 1 = both parties are individual states (bilateral)
  pivot_longer(cols = c(country1, country2), 
               names_to = "position", 
               values_to = "country") %>%
  group_by(country) %>%
  summarise(treaty_count = n(), .groups = "drop") %>%
  arrange(desc(treaty_count)) %>%
  slice_head(n = 20)  # Top 20 countries

plot4b <- ggplot(country_participation, aes(x = reorder(country, treaty_count), y = treaty_count, fill = treaty_count)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = comma(treaty_count)), hjust = -0.2, size = 3.5) +
  coord_flip() +
  labs(
    title = "Top 20 Countries by Bilateral Treaty Participation",
    subtitle = "Countries with most bilateral (state-to-state) treaty records",
    x = "Country",
    y = "Number of Treaty Records",
    caption = "Source: DESTA v2.1 | Bilateral = both parties are individual states (typememb = 1)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(color = "gray50", size = 9)
  ) +
  scale_fill_gradient(low = "#3498DB", high = "#E74C3C") +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.15)))

ggsave("plots/plot4b_top_countries.png", plot4b, 
       width = 12, height = 8, dpi = 100, bg = "white")

# ============================================================================
# PLOT 5: Stacked bar of regions by decade
# ============================================================================
cat("Generating Plot 5: Regions by decade...\n")

treaties_region_decade <- desta %>%
  filter(!is.na(year) & !is.na(regioncon)) %>%
  mutate(decade = floor(year / 10) * 10) %>%
  group_by(decade, regioncon) %>%
  summarise(count = n(), .groups = "drop")

plot5 <- ggplot(treaties_region_decade, aes(x = decade, y = count, fill = regioncon)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(
    title = "Trade Treaty Records by Region and Decade",
    subtitle = "Temporal evolution of regional trade agreements (1940s-2020s)",
    x = "Decade",
    y = "Number of Treaty Records",
    fill = "Region",
    caption = "Source: DESTA v2.1"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(color = "gray40"),
    panel.grid.minor = element_blank(),
    legend.position = "right",
    legend.title = element_text(face = "bold"),
    plot.caption = element_text(color = "gray50", size = 9)
  ) +
  scale_fill_brewer(palette = "Set2") +
  scale_x_continuous(breaks = seq(1940, 2020, 10)) +
  scale_y_continuous(labels = comma, expand = expansion(mult = c(0, 0.05)))

ggsave("plots/plot5_regions_by_decade.png", plot5, 
       width = 12, height = 8, dpi = 100, bg = "white")

# ============================================================================
# Summary Statistics
# ============================================================================
cat("\n=== ANALYSIS COMPLETE ===\n")
cat("All plots saved to plots/ directory:\n")
cat("  - plot1_treaties_per_year.png\n")
cat("  - plot2_treaties_by_region.png\n")
cat("  - plot3_entry_types.png\n")
cat("  - plot4_membership_types.png\n")
cat("  - plot4b_top_countries.png\n")
cat("  - plot5_regions_by_decade.png\n")

# Additional summary statistics
cat("\n=== ADDITIONAL INSIGHTS ===\n")
cat("Unique base treaties:", n_distinct(desta$base_treaty), "\n")
cat("Unique countries:", n_distinct(c(desta$country1, desta$country2)), "\n")
cat("WTO-listed agreements:", sum(desta$wto_listed == 1, na.rm = TRUE), 
    "(", round(sum(desta$wto_listed == 1, na.rm = TRUE) / nrow(desta) * 100, 1), "%)\n")

cat("\nPeak treaty-signing years:\n")
top_years <- desta %>%
  group_by(year) %>%
  summarise(count = n(), .groups = "drop") %>%
  arrange(desc(count)) %>%
  slice_head(n = 5)
print(top_years)

cat("\nScript execution completed successfully!\n")
