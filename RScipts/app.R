# ==============================================================================
# R Shiny Dashboard for Trade Network Centrality Analysis
# ==============================================================================

library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(igraph)
library(dplyr)
library(tidyr)
library(scales)

# ==============================================================================
# DATA LOADING & PREPROCESSING
# ==============================================================================

# Load network data
edges <- read.csv("network_edges.csv", stringsAsFactors = FALSE)
nodes <- read.csv("network_nodes.csv", stringsAsFactors = FALSE)

# Build igraph network
g <- graph_from_data_frame(d = edges, vertices = nodes, directed = FALSE)

# Compute centrality measures
degree_raw <- degree(g)
closeness_raw <- closeness(g)
betweenness_raw <- betweenness(g)
eigenvector_raw <- eigen_centrality(g)$vector
pagerank_raw <- page_rank(g)$vector

# Create centrality dataframe
centrality_df <- data.frame(
  country = V(g)$name,
  degree_raw = degree_raw,
  closeness_raw = closeness_raw,
  betweenness_raw = betweenness_raw,
  eigenvector_raw = eigenvector_raw,
  pagerank_raw = pagerank_raw,
  stringsAsFactors = FALSE
)

# Normalize centrality scores (0-1 range)
normalize <- function(x) {
  if (max(x) == min(x)) return(rep(0.5, length(x)))
  (x - min(x)) / (max(x) - min(x))
}

centrality_df <- centrality_df %>%
  mutate(
    degree_norm = normalize(degree_raw),
    closeness_norm = normalize(closeness_raw),
    betweenness_norm = normalize(betweenness_raw),
    eigenvector_norm = normalize(eigenvector_raw),
    pagerank_norm = normalize(pagerank_raw)
  )

# Compute composite score (mean of normalized measures)
centrality_df <- centrality_df %>%
  mutate(
    composite_score = (degree_norm + closeness_norm + betweenness_norm + 
                       eigenvector_norm + pagerank_norm) / 5
  ) %>%
  arrange(desc(composite_score)) %>%
  mutate(rank = row_number())

# Add treaty count and partner count from nodes
centrality_df <- centrality_df %>%
  left_join(nodes %>% select(country, total_treaties), by = "country") %>%
  rename(treaty_count = total_treaties) %>%
  mutate(partner_count = degree_raw)

# Calculate network statistics
network_density <- edge_density(g)
country_count <- vcount(g)
edge_count <- ecount(g)
top_influencer <- centrality_df$country[1]

# ==============================================================================
# UI DEFINITION
# ==============================================================================

ui <- dashboardPage(
  skin = "blue",
  
  # Header
  dashboardHeader(title = "Trade Network Dashboard"),
  
  # Sidebar
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Centrality Charts", tabName = "centrality", icon = icon("chart-bar")),
      menuItem("Country Profile", tabName = "profile", icon = icon("globe")),
      menuItem("Data Table", tabName = "datatable", icon = icon("table"))
    ),
    hr(),
    sliderInput("global_top_n", 
                "Top N countries (by treaties)",
                min = 5, max = nrow(centrality_df), value = 50, step = 5)
  ),
  
  # Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .small-box h3 { font-size: 32px; }
        .radar-container { height: 400px; }
        .value-box-custom { padding: 10px; }
      "))
    ),
    
    tabItems(
      # ========================================================================
      # TAB 1: OVERVIEW
      # ========================================================================
      tabItem(
        tabName = "overview",
        h2("Network Overview"),
        
        # KPI Value Boxes
        fluidRow(
          valueBoxOutput("country_count_box", width = 3),
          valueBoxOutput("edge_count_box", width = 3),
          valueBoxOutput("density_box", width = 3),
          valueBoxOutput("top_influencer_box", width = 3)
        ),
        
        fluidRow(
          # About panel
          box(
            title = "About This Dashboard",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            p("This dashboard analyzes the global trade agreement network using the DESTA dataset."),
            tags$ul(
              tags$li(strong("Nodes:"), " Countries participating in trade agreements"),
              tags$li(strong("Edges:"), " Bilateral trade relationships"),
              tags$li(strong("Centrality Measures:"), " Five metrics quantifying country influence")
            ),
            hr(),
            h5("Centrality Measures:"),
            tags$ul(
              tags$li(strong("Degree:"), " Number of direct partners"),
              tags$li(strong("Closeness:"), " Average distance to all others"),
              tags$li(strong("Betweenness:"), " Broker position between others"),
              tags$li(strong("Eigenvector:"), " Connected to well-connected"),
              tags$li(strong("PageRank:"), " Weighted importance score")
            )
          ),
          
          # Top 10 composite score chart
          box(
            title = "Top 10 Countries by Composite Score",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            plotlyOutput("top10_chart", height = 400)
          )
        )
      ),
      
      # ========================================================================
      # TAB 2: CENTRALITY CHARTS
      # ========================================================================
      tabItem(
        tabName = "centrality",
        h2("Centrality Analysis"),
        
        fluidRow(
          box(
            title = "Chart Controls",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(4,
                selectInput("centrality_measure",
                            "Select Ranking Measure:",
                            choices = c("Composite Score" = "composite_score",
                                      "Degree" = "degree_norm",
                                      "Closeness" = "closeness_norm",
                                      "Betweenness" = "betweenness_norm",
                                      "Eigenvector" = "eigenvector_norm",
                                      "PageRank" = "pagerank_norm"),
                            selected = "composite_score")
              ),
              column(4,
                sliderInput("chart_top_n",
                            "Top N Countries:",
                            min = 5, max = 30, value = 15, step = 1)
              ),
              column(4,
                div(style = "margin-top: 25px;",
                    strong("Use the controls to explore different centrality rankings")
                )
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "Ranked Bar Chart (Selected Measure)",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("ranked_bar_chart", height = 500)
          ),
          box(
            title = "All Five Normalized Measures (Top N)",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("grouped_bar_chart", height = 500)
          )
        ),
        
        fluidRow(
          box(
            title = "Scatter Plot: Any Two Measures",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(3,
                selectInput("scatter_x",
                            "X-axis Measure:",
                            choices = c("Degree" = "degree_norm",
                                      "Closeness" = "closeness_norm",
                                      "Betweenness" = "betweenness_norm",
                                      "Eigenvector" = "eigenvector_norm",
                                      "PageRank" = "pagerank_norm"),
                            selected = "degree_norm")
              ),
              column(3,
                selectInput("scatter_y",
                            "Y-axis Measure:",
                            choices = c("Degree" = "degree_norm",
                                      "Closeness" = "closeness_norm",
                                      "Betweenness" = "betweenness_norm",
                                      "Eigenvector" = "eigenvector_norm",
                                      "PageRank" = "pagerank_norm"),
                            selected = "betweenness_norm")
              ),
              column(6,
                plotlyOutput("scatter_plot", height = 450)
              )
            )
          )
        )
      ),
      
      # ========================================================================
      # TAB 3: COUNTRY PROFILE
      # ========================================================================
      tabItem(
        tabName = "profile",
        h2("Country Profile"),
        
        fluidRow(
          box(
            title = "Select Country",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            selectInput("selected_country",
                       "Choose a country to view its profile:",
                       choices = sort(centrality_df$country),
                       selected = centrality_df$country[1])
          )
        ),
        
        fluidRow(
          valueBoxOutput("profile_rank_box", width = 3),
          valueBoxOutput("profile_treaties_box", width = 3),
          valueBoxOutput("profile_partners_box", width = 3),
          valueBoxOutput("profile_betweenness_box", width = 3)
        ),
        
        fluidRow(
          box(
            title = "Centrality Radar Chart",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("radar_chart", height = 500)
          )
        )
      ),
      
      # ========================================================================
      # TAB 4: DATA TABLE
      # ========================================================================
      tabItem(
        tabName = "datatable",
        h2("Full Centrality Data"),
        
        fluidRow(
          box(
            title = "Centrality Scores Table",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            downloadButton("download_csv", "Download CSV", class = "btn-success"),
            hr(),
            DTOutput("centrality_table")
          )
        )
      )
    )
  )
)

# ==============================================================================
# SERVER LOGIC
# ==============================================================================

server <- function(input, output, session) {
  
  # Reactive filtered data based on global slider
  filtered_data <- reactive({
    centrality_df %>%
      arrange(desc(treaty_count)) %>%
      head(input$global_top_n)
  })
  
  # ==========================================================================
  # TAB 1: OVERVIEW OUTPUTS
  # ==========================================================================
  
  output$country_count_box <- renderValueBox({
    valueBox(
      value = country_count,
      subtitle = "Countries in Network",
      icon = icon("globe"),
      color = "blue"
    )
  })
  
  output$edge_count_box <- renderValueBox({
    valueBox(
      value = edge_count,
      subtitle = "Bilateral Relationships",
      icon = icon("link"),
      color = "green"
    )
  })
  
  output$density_box <- renderValueBox({
    valueBox(
      value = sprintf("%.3f", network_density),
      subtitle = "Network Density",
      icon = icon("project-diagram"),
      color = "yellow"
    )
  })
  
  output$top_influencer_box <- renderValueBox({
    valueBox(
      value = top_influencer,
      subtitle = "Top Influencer",
      icon = icon("crown"),
      color = "red"
    )
  })
  
  output$top10_chart <- renderPlotly({
    top10 <- centrality_df %>%
      head(10) %>%
      arrange(composite_score)
    
    plot_ly(
      data = top10,
      x = ~composite_score,
      y = ~reorder(country, composite_score),
      type = "bar",
      orientation = "h",
      marker = list(
        color = ~composite_score,
        colorscale = "Viridis",
        showscale = TRUE,
        colorbar = list(title = "Score")
      ),
      text = ~paste0(country, ": ", round(composite_score, 3)),
      hoverinfo = "text"
    ) %>%
      layout(
        xaxis = list(title = "Composite Score"),
        yaxis = list(title = ""),
        margin = list(l = 100)
      )
  })
  
  # ==========================================================================
  # TAB 2: CENTRALITY CHARTS OUTPUTS
  # ==========================================================================
  
  output$ranked_bar_chart <- renderPlotly({
    measure <- input$centrality_measure
    n <- input$chart_top_n
    
    measure_labels <- c(
      composite_score = "Composite Score",
      degree_norm = "Degree",
      closeness_norm = "Closeness",
      betweenness_norm = "Betweenness",
      eigenvector_norm = "Eigenvector",
      pagerank_norm = "PageRank"
    )
    
    data_top_n <- centrality_df %>%
      arrange(desc(.data[[measure]])) %>%
      head(n) %>%
      arrange(.data[[measure]])
    
    plot_ly(
      data = data_top_n,
      x = ~.data[[measure]],
      y = ~reorder(country, .data[[measure]]),
      type = "bar",
      orientation = "h",
      marker = list(color = "steelblue"),
      text = ~paste0(country, ": ", round(.data[[measure]], 3)),
      hoverinfo = "text"
    ) %>%
      layout(
        title = paste("Top", n, "by", measure_labels[measure]),
        xaxis = list(title = measure_labels[measure]),
        yaxis = list(title = ""),
        margin = list(l = 120)
      )
  })
  
  output$grouped_bar_chart <- renderPlotly({
    n <- input$chart_top_n
    
    # Get top N by selected measure, then show all 5 measures
    top_countries <- centrality_df %>%
      arrange(desc(.data[[input$centrality_measure]])) %>%
      head(n) %>%
      pull(country)
    
    data_grouped <- centrality_df %>%
      filter(country %in% top_countries) %>%
      select(country, degree_norm, closeness_norm, betweenness_norm, 
             eigenvector_norm, pagerank_norm) %>%
      pivot_longer(cols = -country, names_to = "measure", values_to = "value") %>%
      mutate(
        measure = factor(measure, 
                        levels = c("degree_norm", "closeness_norm", "betweenness_norm",
                                 "eigenvector_norm", "pagerank_norm"),
                        labels = c("Degree", "Closeness", "Betweenness",
                                 "Eigenvector", "PageRank"))
      )
    
    plot_ly(
      data = data_grouped,
      x = ~country,
      y = ~value,
      color = ~measure,
      type = "bar",
      colors = "Set2"
    ) %>%
      layout(
        title = paste("All Five Measures for Top", n, "Countries"),
        xaxis = list(title = "", tickangle = -45),
        yaxis = list(title = "Normalized Score"),
        barmode = "group",
        legend = list(title = list(text = "Measure")),
        margin = list(b = 100)
      )
  })
  
  output$scatter_plot <- renderPlotly({
    x_measure <- input$scatter_x
    y_measure <- input$scatter_y
    
    measure_labels <- c(
      degree_norm = "Degree",
      closeness_norm = "Closeness",
      betweenness_norm = "Betweenness",
      eigenvector_norm = "Eigenvector",
      pagerank_norm = "PageRank"
    )
    
    plot_ly(
      data = centrality_df,
      x = ~.data[[x_measure]],
      y = ~.data[[y_measure]],
      type = "scatter",
      mode = "markers",
      marker = list(
        size = ~treaty_count,
        sizemode = "diameter",
        sizeref = 2,
        color = ~composite_score,
        colorscale = "Viridis",
        showscale = TRUE,
        colorbar = list(title = "Composite<br>Score"),
        line = list(color = "white", width = 0.5)
      ),
      text = ~paste0(
        "<b>", country, "</b><br>",
        measure_labels[x_measure], ": ", round(.data[[x_measure]], 3), "<br>",
        measure_labels[y_measure], ": ", round(.data[[y_measure]], 3), "<br>",
        "Treaties: ", treaty_count, "<br>",
        "Composite Score: ", round(composite_score, 3)
      ),
      hoverinfo = "text"
    ) %>%
      layout(
        title = paste(measure_labels[x_measure], "vs", measure_labels[y_measure]),
        xaxis = list(title = measure_labels[x_measure]),
        yaxis = list(title = measure_labels[y_measure])
      )
  })
  
  # ==========================================================================
  # TAB 3: COUNTRY PROFILE OUTPUTS
  # ==========================================================================
  
  country_data <- reactive({
    centrality_df %>% filter(country == input$selected_country)
  })
  
  output$profile_rank_box <- renderValueBox({
    data <- country_data()
    valueBox(
      value = paste("#", data$rank),
      subtitle = "Composite Rank",
      icon = icon("trophy"),
      color = "yellow"
    )
  })
  
  output$profile_treaties_box <- renderValueBox({
    data <- country_data()
    valueBox(
      value = data$treaty_count,
      subtitle = "Total Treaties",
      icon = icon("file-contract"),
      color = "blue"
    )
  })
  
  output$profile_partners_box <- renderValueBox({
    data <- country_data()
    valueBox(
      value = data$partner_count,
      subtitle = "Trade Partners",
      icon = icon("handshake"),
      color = "green"
    )
  })
  
  output$profile_betweenness_box <- renderValueBox({
    data <- country_data()
    valueBox(
      value = round(data$betweenness_raw, 1),
      subtitle = "Betweenness (Raw)",
      icon = icon("network-wired"),
      color = "red"
    )
  })
  
  output$radar_chart <- renderPlotly({
    data <- country_data()
    
    # Prepare radar chart data
    radar_data <- data.frame(
      measure = c("Degree", "Closeness", "Betweenness", "Eigenvector", "PageRank"),
      value = c(data$degree_norm, data$closeness_norm, data$betweenness_norm,
               data$eigenvector_norm, data$pagerank_norm)
    )
    
    plot_ly(
      type = "scatterpolar",
      mode = "lines+markers",
      fill = "toself"
    ) %>%
      add_trace(
        r = c(radar_data$value, radar_data$value[1]),
        theta = c(radar_data$measure, radar_data$measure[1]),
        name = input$selected_country,
        fillcolor = "rgba(70, 130, 180, 0.3)",
        line = list(color = "steelblue", width = 2),
        marker = list(size = 8, color = "steelblue")
      ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible = TRUE,
            range = c(0, 1),
            tickformat = ".2f"
          )
        ),
        title = paste("Normalized Centrality Profile:", input$selected_country),
        showlegend = FALSE
      )
  })
  
  # ==========================================================================
  # TAB 4: DATA TABLE OUTPUTS
  # ==========================================================================
  
  output$centrality_table <- renderDT({
    data_display <- filtered_data() %>%
      select(
        Rank = rank,
        Country = country,
        Treaties = treaty_count,
        Partners = partner_count,
        Composite = composite_score,
        Degree = degree_norm,
        Closeness = closeness_norm,
        Betweenness = betweenness_norm,
        Eigenvector = eigenvector_norm,
        PageRank = pagerank_norm
      ) %>%
      mutate(
        Composite = round(Composite, 4),
        Degree = round(Degree, 4),
        Closeness = round(Closeness, 4),
        Betweenness = round(Betweenness, 4),
        Eigenvector = round(Eigenvector, 4),
        PageRank = round(PageRank, 4)
      )
    
    datatable(
      data_display,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(0, 'asc')),
        columnDefs = list(
          list(className = 'dt-center', targets = '_all')
        )
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        'Composite',
        background = styleColorBar(data_display$Composite, 'lightblue'),
        backgroundSize = '100% 90%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      )
  })
  
  output$download_csv <- downloadHandler(
    filename = function() {
      paste0("network_centrality_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(filtered_data(), file, row.names = FALSE)
    }
  )
}

# ==============================================================================
# RUN APPLICATION
# ==============================================================================

shinyApp(ui = ui, server = server)
