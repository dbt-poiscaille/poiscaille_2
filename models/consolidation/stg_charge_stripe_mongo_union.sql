{{
  config(
    materialized = 'table',
    labels = {'type': 'stripe', 'contains_pie': 'no', 'category':'source'}  
   )
}}

WITH stripe_charges_consolidation AS (
    SELECT
        charge_id,
        charge_date,
        stripe_customer_id,
        receipt_email,
        charge_type,
        charges_amount,
        amount_refunded,
        'Stripe' as data_from

    FROM {{ ref('stg_charges_consolidation')}}
    -- WHERE
    --     charge_date BETWEEN '2022-01-01' AND '2022-06-30'
),

mongodb_sale_consolidation_by_date AS (
    SELECT
        sale_id,
        customerid,
        email as email,
        sale_date,
        type_sale,
        price_ttc,
        chargeid,
        'MongoDB' as data_from
    FROM
        {{ ref('stg_mongo_sale_consolidation')}}
)

SELECT
    stripe_charges_consolidation.charge_id as stripe_charge_id,
    mongodb_sale_consolidation_by_date.chargeid as mongo_charge_id,
    mongodb_sale_consolidation_by_date.sale_id as mongo_sale_id,

    COALESCE(stripe_charges_consolidation.charge_date, mongodb_sale_consolidation_by_date.sale_date) AS date,
    COALESCE(stripe_charges_consolidation.stripe_customer_id, mongodb_sale_consolidation_by_date.customerid) AS customerid,
    COALESCE(stripe_charges_consolidation.receipt_email, mongodb_sale_consolidation_by_date.email) AS email,
    COALESCE(stripe_charges_consolidation.charge_type, mongodb_sale_consolidation_by_date.type_sale) AS type_sale,
    COALESCE(stripe_charges_consolidation.charges_amount, mongodb_sale_consolidation_by_date.price_ttc) AS amount,
    COALESCE(stripe_charges_consolidation.data_from, mongodb_sale_consolidation_by_date.data_from) AS data_from
FROM
    stripe_charges_consolidation
    FULL OUTER JOIN mongodb_sale_consolidation_by_date
    ON
        stripe_charges_consolidation.stripe_customer_id = mongodb_sale_consolidation_by_date.customerid
        and stripe_charges_consolidation.charge_id = mongodb_sale_consolidation_by_date.chargeid
where COALESCE(stripe_charges_consolidation.data_from, mongodb_sale_consolidation_by_date.data_from) = 'MongoDB'
ORDER BY COALESCE(stripe_charges_consolidation.charge_date, mongodb_sale_consolidation_by_date.sale_date) desc