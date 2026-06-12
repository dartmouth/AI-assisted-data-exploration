# DESTA List of Treaties - Field Descriptions

## Dataset Overview
The DESTA (Design of Trade Agreements) dataset contains information about international trade agreements. This file describes each field in the `desta_list_of_treaties.xlsx` dataset.

**Source**: Dür A., Baccini L., and Elsig M. 2014. "The Design of International Trade Agreements: Introducing a New Dataset." The Review of International Organizations, 9(3): 353-375. Version 2.1., 2022

**Dataset Size**: 18,329 records representing country pairs in 856 base treaties

---

## Field Descriptions

### 1. **country1** (Character)
- **Description**: Name of the first country in the bilateral treaty pair
- **Examples**: Afghanistan, Algeria, Egypt, Ghana, Guinea
- **Notes**: Used together with country2 to represent a bilateral relationship in a trade agreement

### 2. **country2** (Character)
- **Description**: Name of the second country in the bilateral treaty pair
- **Examples**: India, Egypt, Ghana, Guinea, Mali
- **Notes**: Forms a pair with country1 to represent the trading relationship

### 3. **iso1** (Numeric)
- **Description**: ISO 3166-1 numeric country code for country1
- **Range**: 4 - 900
- **Purpose**: Standardized country identifier for data linking and analysis

### 4. **iso2** (Numeric)
- **Description**: ISO 3166-1 numeric country code for country2
- **Range**: 24 - 900
- **Purpose**: Standardized country identifier for data linking and analysis

### 5. **number** (Character)
- **Description**: Unique treaty identification number
- **Count**: 1,116 unique treaty numbers
- **Purpose**: Identifies distinct trade agreements in the dataset

### 6. **base_treaty** (Numeric)
- **Description**: Identifier for the base (original) treaty
- **Count**: 856 unique base treaties
- **Purpose**: Links accessions and amendments back to their original treaty
- **Notes**: Multiple records may share the same base_treaty if countries acceded at different times

### 7. **name** (Character)
- **Description**: Full name or title of the trade agreement
- **Examples**: 
  - "Afghanistan India"
  - "African Common Market"
  - "African Economic Community"
- **Notes**: May be descriptive (bilateral agreements) or formal treaty names

### 8. **entry_type** (Character)
- **Description**: Indicates how the treaty record entered the dataset
- **Values**:
  - `base_treaty` (14,440 records): Original treaty signature
  - `accession` (3,391 records): Country joining an existing treaty
  - `amendment` (498 records): A modification or update to an existing treaty
- **Purpose**: Distinguishes between original treaties and subsequent modifications
- **Notes**: `consolidated` is NOT a value of this field — consolidation status is captured separately by the `consolidated` binary field

### 9. **consolidated** (Numeric/Binary)
- **Description**: Indicates whether this is a consolidated treaty version
- **Values**:
  - `0` (17,831 records): Not consolidated
  - `1` (498 records): Consolidated treaty
- **Purpose**: Flags treaties that have been consolidated with amendments

### 10. **year** (Numeric)
- **Description**: Year the treaty was signed
- **Range**: 1948 - 2021
- **Notes**: Represents the signature date, not necessarily when it entered into force

### 11. **entryforceyear** (Numeric)
- **Description**: Year the treaty officially entered into force
- **Range**: 1949 - 2021
- **Notes**: May differ from signature year; this is when the treaty became legally binding

### 12. **language** (Character)
- **Description**: Language(s) in which the treaty document is available
- **Unique Values**: 8 different languages
- **Examples**: English, Arabic, French, Spanish
- **Notes**: Some records have NA values indicating language information not available

### 13. **typememb** (Numeric)
- **Description**: Type of membership or agreement structure
- **Values**: 1, 2, 3, 4, 5, 6
- **Distribution**:
  - Type 1: 611 records
  - Type 2: 6,731 records (most common)
  - Type 3: 1,707 records
  - Type 4: 5,889 records
  - Type 5: 1,625 records
  - Type 6: 1,766 records
- **Interpretation**: Describes the membership type of the two parties in each dyad:
  - `1` = Both parties are individual states
  - `2` = One party is a group of states; the other is an individual state
  - `3` = Both parties are groups of states
  - `4` = One party is a customs union; the other is an individual state
  - `5` = One party is a customs union; the other is a group of states
  - `6` = Both parties are customs unions
- **Note**: This field describes *who* the parties are, not the depth or bilaterality of the agreement

### 14. **regioncon** (Character)
- **Description**: Regional configuration or geographic classification of the treaty
- **Values and Distribution**:
  - `Intercontinental`: 9,316 records (most common - cross-regional agreements)
  - `Africa`: 4,463 records
  - `Europe`: 2,613 records
  - `Americas`: 1,366 records
  - `Asia`: 502 records
  - `Oceania`: 69 records
- **Purpose**: Categorizes treaties by their geographic scope

### 15. **wto_listed** (Numeric/Binary)
- **Description**: Indicates whether the agreement is officially notified to/listed by the World Trade Organization
- **Values**:
  - `0` (10,333 records): Not listed by WTO
  - `1` (7,996 records): Listed by WTO
- **Purpose**: Indicates formal WTO recognition and notification status

### 16. **wto_name** (Character)
- **Description**: Official name of the agreement as listed by the WTO
- **Coverage**: 7,970 non-NA entries out of 18,329 total records
- **Notes**: Only populated for agreements that are WTO-listed (wto_listed = 1)

---

## Data Structure Notes

1. **Bilateral Representation**: Each trade agreement involving multiple countries is represented as multiple bilateral pairs. For example, a 5-country agreement would have 10 rows (one for each country pair).

2. **Treaty Evolution**: The dataset tracks treaty evolution through:
   - Original treaties (entry_type = "base_treaty")
   - New countries joining (entry_type = "accession")
   - Amendments to existing treaties (entry_type = "amendment"); separately, the `consolidated` field flags whether a record represents a consolidated version

3. **Temporal Coverage**: The dataset spans from 1948 (post-WWII era) to 2021, covering the entire modern period of international trade agreement formation.

4. **WTO Integration**: Approximately 44% of records are WTO-listed agreements, representing formally notified trade agreements under WTO rules.

5. **Geographic Distribution**: Most agreements (51%) are intercontinental, reflecting the global nature of modern trade agreements.

---

## Common Analysis Patterns

- **Network Analysis**: Use country1/country2 pairs to build trade network graphs
- **Temporal Analysis**: Use year/entryforceyear to track agreement formation over time
- **Regional Patterns**: Use regioncon to analyze regional integration patterns
- **WTO Coverage**: Use wto_listed to analyze formal vs. informal trade agreements
- **Treaty Depth**: Use typememb to analyze different levels of trade integration
