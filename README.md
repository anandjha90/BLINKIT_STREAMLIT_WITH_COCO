# Blinkit Analytics Dashboard

A comprehensive Streamlit dashboard for Blinkit (quick-commerce) analytics, built entirely using **Cortex Code (CoCo)** on Snowflake.

## Dashboard Preview

### Tabs & KPIs

| Tab | Metrics & Charts |
|-----|-----------------|
| **Top KPIs** | Total Orders, Revenue, Avg Order Value, On-Time %, Avg Distance, Items Sold |
| **Orders** | Orders/Revenue over time, Delivery status donut, Revenue by payment method |
| **Delivery** | Distance distribution, Top delay reasons, Status breakdown with progress bars |
| **Marketing** | Spend vs Revenue by channel, ROAS, Conversions by audience, Impressions trend |
| **Customer Insights** | Unique/Repeat customers, Repeat rate, Segmentation, New customers over time, Top 10 by revenue |
| **Raw Data** | Browsable view of all 4 tables |

### Filters (Sidebar)
- Date range picker
- Delivery status
- Payment method
- Marketing channel

## Setup

### 1. Snowflake Setup

Run the SQL setup script to create the database, tables, and load synthetic data:

```sql
-- Execute in Snowflake worksheet or via SnowSQL
SOURCE snowflake_setup.sql
```

Or copy-paste the contents of `snowflake_setup.sql` into a Snowflake worksheet and run.

### 2. Python Dependencies

```bash
pip install -r requirements.txt
```

### 3. Snowflake Connection

The app uses `snowflake.connector` with a named connection. Configure your connection in `~/.snowflake/connections.toml`:

```toml
[QK61286]
account = "your_account"
user = "your_user"
authenticator = "externalbrowser"  # or your auth method
```

Or set the environment variable:

```bash
export SNOWFLAKE_CONNECTION_NAME=your_connection_name
```

### 4. Run the Dashboard

```bash
streamlit run blinkit_dashboard.py
```

Open http://localhost:8501 in your browser.

## Tech Stack

- **Streamlit** - Dashboard UI
- **Snowflake** - Data warehouse
- **Altair** - Interactive charts
- **Pandas** - Data manipulation
- **Cortex Code (CoCo)** - AI-assisted development

## Project Structure

```
BLINKIT_STREAMLIT_WITH_COCO/
├── blinkit_dashboard.py    # Main Streamlit application
├── snowflake_setup.sql     # Database, tables & synthetic data setup
├── requirements.txt        # Python dependencies
├── .gitignore              # Git ignore rules
└── README.md               # This file
```
