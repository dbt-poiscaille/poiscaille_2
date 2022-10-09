{{
  config(
    materialized = 'table',
    labels = {'type': 'mongodb', 'contains_pie': 'no', 'category':'source'}  
   )
}}


WITH  sale_data AS (
select  
 distinct 
  shippingat,
  DATE_ADD(cast(shippingat as date), INTERVAL 1 DAY) as sale_date,
  DATE_TRUNC(cast(shippingat as date), WEEK(MONDAY)) as first_day_week,
  LAST_DAY(cast(shippingat as date), WEEK(MONDAY)) as last_day_week,        
  sale_id,
  place_id, 
  company, 
  firstname,
  lastname,
  phone,
  user_id,
  email,
  createdat,
  subscription_id,
  price_ttc as price_ttc_raw,
  --round(cast(price_ttc as int64)/100,2) as price_ttc,
  -- round(cast(offerings_value_price_ttc as int64)/100,2) as price_ttc,  
  refundedprice /100 as amount_refund,
  customerid,
  subscriptionid, 
  subscription_rate,
  subscription_status,
  case when subscription_rate = 'biweekly' then 'Livraison chaque quinzaine'
       when subscription_rate = 'weekly' then 'Livraison chaque semaine'
       when subscription_rate = 'fourweekly' then 'Livraison chaque mois'
       end as subscription_type,   
  subscription_total_casiers,
  channel,
  offerings_value_channel,
  CASE WHEN channel = 'shop' THEN 'Boutique'
      WHEN  channel = 'combo' and offerings_value_channel = 'combo' THEN 'Abonnement'
      WHEN  channel = 'combo' and offerings_value_channel = 'shop' THEN 'Petit plus'
  END AS type_sale,  
  round(cast(offerings_value_price_ttc as int64)/100,2) as price_details_ttc,
  offerings_value_price_ttc,
  offerings_value_price_tax,
  offerings_value_price_ht,
  subscription_price,
  offerings_value_count,
  --offerings_value_name,
  --offerings_value_items_value_product_name,
  --offerings_value_items_value_product_id,
  --offerings_value_items_value_product_type,
  invoiceitemid,
  chargeid,
  status
  FROM  {{ ref('src_mongodb_sale') }} 
  order by subscription_total_casiers asc 
),

sale_data_final as (
  select
    *,
  case
    when type_sale = 'Boutique' then round(cast(offerings_value_price_ttc*offerings_value_count as int64)/100,2)
    when type_sale = 'Abonnement' then round(cast(subscription_price as int64)/100,2) 
    when type_sale = 'Petit plus' then round(cast(price_ttc_raw - subscription_price as int64)/100,2)  
  end as price_ttc
  from sale_data
),
  

place_data AS (
SELECT
  place_id,
  place_name,
  place_owner,
  place_phone,
  place_city,
  place_address,
  place_codepostal,
  place_email,
  place_coupon,
  place_lng,
  place_lat,
  place_geocode,
  place_createdat,
  shipping_pickup,
  shipping_delay,
  place_company,
  place_coupon_users,
  place_coupon_amount,
  shipping_company,
  days_since_in_bdd,
  months_since_in_bdd,
  year_since_in_bdd,
  type_livraison,
  place_storage,
  place_icebox,
  place_pickup,
  place_openings_schedule,
  place_openings_hidden,
  place_openings_day,
  place_openings_depositschedule,
  nom_departement,
  nom_region,
  zone
FROM  {{ ref('stg_mongo_place_consolidation') }})

SELECT sale_data_final.*, 
  place_name,
  place_owner,
  place_phone,
  place_city,
  place_address,
  place_codepostal,
  place_email,
  place_coupon,
  place_lng,
  place_lat,
  place_geocode,
  place_createdat,
  shipping_pickup,
  shipping_delay,
  place_company,
  place_coupon_users,
  place_coupon_amount,
  shipping_company,
  days_since_in_bdd,
  months_since_in_bdd,
  year_since_in_bdd,
  type_livraison,
  place_storage,
  place_icebox,
  place_pickup,
  place_openings_schedule,
  place_openings_hidden,
  place_openings_day,
  place_openings_depositschedule,
  nom_departement,
  nom_region,
  zone
FROM sale_data_final LEFT JOIN place_data ON sale_data_final.place_id = place_data.place_id
-- where sale_id = '62cc5b3a9a26adf00ba40d58'
order by sale_date desc ,  sale_id asc 




