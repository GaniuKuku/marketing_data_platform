{{
    config(
        materialized='incremental',
        unique_key='campaign_daily_id',
        incremental_strategy='merge',
        on_schema_change='sync_all_columns'
    )
}}

with ad_level_data as (
    select
        date_day,
        platform,
        account_id,
        account_name,
        campaign_id,
        campaign_name,
        currency_code,
        spend,
        impressions,
        clicks,
        ad_id,
        updated_at
    from {{ ref('int_marketing_ads') }}
    
    {% if is_incremental() %}
        -- Optimized scalar lookback window for distributed cloud engines
        where date_day >= (select date_add(max(date_day), -3) from {{ this }})
    {% endif %}
),

campaign_daily_aggregated as (
    select
        -- 1. Unique Campaign-Daily Surrogate Key Hash
        {{ dbt_utils.generate_surrogate_key(['date_day', 'platform', 'campaign_id']) }} as campaign_daily_id,
        
        -- 2. Core Dimensional Attributes
        date_day,
        platform,
        account_id,
        coalesce(max(account_name), 'Unknown Account') as account_name,
        campaign_id,
        coalesce(max(campaign_name), 'Unknown Campaign') as campaign_name,
        coalesce(max(currency_code), 'USD') as currency_code,

        -- 3. Hardened Financial and Traffic Metrics
        cast(sum(spend) as decimal(18, 2)) as spend,
        cast(sum(impressions) as bigint) as impressions,
        cast(sum(clicks) as bigint) as clicks,
        count(distinct ad_id) as active_ads_count,

        -- 4. Safe Business Performance Indicators (Insulated from Zero Crashes)
        cast(
            case when sum(impressions) > 0 then (sum(clicks) * 1.0) / sum(impressions) else 0.0 end 
            as decimal(18, 6)
        ) as ctr,

        cast(
            case when sum(clicks) > 0 then sum(spend) / sum(clicks) else 0.0 end 
            as decimal(18, 4)
        ) as cpc,

        cast(
            case when sum(impressions) > 0 then (sum(spend) / sum(impressions)) * 1000.0 else 0.0 end 
            as decimal(18, 4)
        ) as cpm,

        -- 5. Audit Processing Timestamp
        max(updated_at) as last_updated_at

    from ad_level_data
    group by
        date_day,
        platform,
        account_id,
        campaign_id
)

select
    campaign_daily_id,
    date_day,
    platform,
    account_id,
    account_name,
    campaign_id,
    campaign_name,
    currency_code,
    spend,
    impressions,
    clicks,
    active_ads_count,
    ctr,
    cpc,
    cpm,
    last_updated_at
from campaign_daily_aggregated
