{{
    config(
        materialized='view'
    )
}}

with facebook_ads as (
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
    from {{ ref('stg_facebook_ads') }}
),

snapchat_ads as (
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
    from {{ ref('stg_snapchat_ads') }}
),

unioned as (
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
    from facebook_ads

    union all

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
    from snapchat_ads
)

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
from unioned
