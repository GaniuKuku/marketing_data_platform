with source as (
    select
        ad_id,
        ad_group_id,
        ad_name,
        ad_detail_updated_at,
        campaign_id,
        account_id,
        campaign_name,
        _surrogate_key,
        ad_group_name,
        ad_group_updated_at,
        ad_detail_id,
        ad_currency_code,
        ad_country,
        ad_spend,
        ad_impressions,
        ad_clicks,
        ad_date,
        data_src
    from {{ source('marketing_raw', 'snapchat_ads_raw') }}
),

cleaned as (
    select
        -- 1. Unique Primary Key Definition
        {{ dbt_utils.generate_surrogate_key(["'snapchat'", 'ad_id', 'ad_date']) }} as ad_daily_id,

        -- 2. Temporal & Platform Classification
        cast(ad_date as date) as date_day,
        'snapchat' as platform,

        -- 3. System Identifiers (Standardized to Text Strings)
        cast(account_id as string) as account_id,
        cast(campaign_id as string) as campaign_id,
        cast(ad_group_id as string) as ad_group_id,
        cast(ad_id as string) as ad_id,

        -- 4. Text Descriptions (Cleaned and Trimmed)
        cast(null as string) as account_name,
        trim(campaign_name) as campaign_name,
        trim(ad_group_name) as ad_group_name,
        trim(ad_name) as ad_name,
        cast(null as string) as ad_status,
        upper(trim(ad_currency_code)) as currency_code,
        upper(trim(ad_country)) as country_code,

        -- 5. Business Performance Metrics (Cleaned, Typed, & Defaulted)
        coalesce(try_cast(ad_spend as decimal(18, 2)), 0.00) as spend,
        coalesce(try_cast(ad_impressions as bigint), 0) as impressions,
        coalesce(try_cast(regexp_replace(ad_clicks, '[^0-9-]', '') as bigint), 0) as clicks,

        -- 6. System Audit Record
        cast(ad_detail_updated_at as timestamp) as updated_at

    from source
    where ad_date is not null
      and ad_id is not null

    -- 7. Data Quality Deduplication Check
    qualify row_number() over (
        partition by ad_id, ad_date
        order by ad_detail_updated_at desc
    ) = 1
)

-- 8. Final Output Selection
select
    ad_daily_id,
    date_day,
    platform,
    account_id,
    campaign_id,
    ad_group_id,
    ad_id,
    account_name,
    campaign_name,
    ad_group_name,
    ad_name,
    ad_status,
    currency_code,
    country_code,
    spend,
    impressions,
    clicks,
    updated_at
from cleaned