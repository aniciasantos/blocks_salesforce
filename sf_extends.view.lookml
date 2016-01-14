- view: account
  extends: _account
  fields:
  
# dimensions #

  - dimension: business_segment
    type: string
    sql_case:
      'Small Business': ${number_of_employees} BETWEEN 0 AND 500
      'Mid-Market': ${number_of_employees} BETWEEN 501 AND 1000
      'Enterprise': ${number_of_employees} > 1000
      else: 'Unknown'    

# measures #

  - measure: percent_of_accounts
    type: percent_of_total
    sql: ${count}
    
  - measure: average_annual_revenue
    type: average
    sql: ${annual_revenue}
    value_format: '$#,##0'
    
  - measure: total_number_of_employees
    type: sum
    sql: ${number_of_employees}
    
  - measure: average_number_of_employees
    type: avg
    sql: ${number_of_employees}
    
  - measure: count_customers
    type: count
    filters:
      account.type: '"Customer"'
    
    
- view: lead
  extends: _lead
  fields:
  - dimension: first_name
    sql: COALESCE(${TABLE}.first_name,${contact.first_name})
    
  - dimension: last_name
    sql: COALESCE(${TABLE}.last_name,${contact.last_name})
    
  - dimension: email
    sql: COALESCE(${TABLE}.email,${contact.email})
    
  - dimension: number_of_employees
    sql: COALESCE(${TABLE}.number_of_employees,${account.number_of_employees})
    
  - dimension: title
    sql: COALESCE(${TABLE}.title,${contact.title})
    
  - dimension: industry
    sql: COALESCE(${TABLE}.industry,${account.industry})        
  
  - dimension: name
    sql: COALESCE(${TABLE}.name,${contact.name})  
    html: |
      <a href="https://na9.salesforce.com/{{ lead.id._value }}" target="_new">
      <img src="https://www.salesforce.com/favicon.ico" height=16 width=16></a>
      {{ linked_value }}
      
  - dimension: number_of_employees_tier
    type: tier
    tiers: [0, 1, 11, 51, 201, 501, 1001, 5001, 10000]
    sql: ${number_of_employees}
    style: integer
    description: "Number of Employees as reported on the Salesforce lead"
  
  - measure: converted_to_contact_count
    type: count
    drill_fields: detail*
    filters:
      converted_contact_id: -null
    
  - measure: converted_to_account_count
    type: count
    drill_fields: detail*
    filters:
      converted_account_id: -null
    
  - measure: converted_to_opportunity_count
    type: count
    drill_fields: detail*
    filters:
      converted_opportunity_id: -null
    
  - measure: conversion_to_contact_percent
    sql: 100.00 * ${converted_to_contact_count} / NULLIF(${count},0)
    type: number
    value_format: '0.00\%'
    
  - measure: conversion_to_account_percent
    sql: 100.00 * ${converted_to_account_count} / NULLIF(${count},0)
    type: number
    value_format: '0.00\%'
    
  - measure: conversion_to_opportunity_percent
    sql: 100.00 * ${converted_to_opportunity_count} / NULLIF(${count},0)
    type: number
    value_format: '0.00\%'
    
  sets:
    detail:
    - id
    - company
    - name
    - title
    - phone
    - email
    - status
    
- view: opportunity
  extends: _opportunity
  fields:
  
# dimensions #

  - dimension: is_lost
    type: yesno
    sql: ${is_closed} AND NOT ${is_won}

  - dimension: probability_group
    sql_case:
      'Won': ${probability} = 100
      'Above 80%': ${probability} > 80
      '60 - 80%': ${probability} > 60
      '40 - 60%': ${probability} > 40
      '20 - 40%': ${probability} > 20
      'Under 20%': ${probability} > 0
      'Lost': ${probability} = 0

  - dimension: days_open
    type: number
    sql: datediff(days, ${created_date}, coalesce(${close_date}, current_date) ) 
    
  - dimension:  created_to_closed_in_60 
    hidden: true
    type: yesno
    sql: ${days_open} <=60 AND ${is_closed} = 'yes' AND ${is_won} = 'yes'     
  
  # measures #
  
  - measure: total_revenue
    type: sum
    sql: ${amount}
    value_format: '$#,##0'
    
  - measure: average_revenue_won
    label: 'Average Revenue (Closed/Won)'
    type: average
    sql: ${amount}
    filters:
      is_won: Yes    
    value_format: '$#,##0' 
    
  - measure: average_revenue_lost
    label: 'Average Revenue (Closed/Lost)'
    type: average
    sql: ${amount}
    filters:
      is_lost: Yes    
    value_format: '$#,##0'     
    
  - measure: total_pipeline_revenue
    type: sum
    sql: ${amount}
    filters:
      is_closed: No
    value_format: '[>=1000000]0.00,,"M";[>=1000]0.00,"K";$0.00'  
    
  - measure: average_deal_style
    type: avg
    sql: ${amount}
    value_format: '$#,##0'
  
  - measure: count_won
    type: count
    filters:
      is_won: Yes
    drill_fields: [opportunity.id, account.name, type]
    
  - measure: average_days_open
    type: avg
    sql: ${days_open}
    
  - measure: count_closed
    type: count
    filters: 
      is_closed: Yes
      
  - measure: count_open
    type: count
    filters:
      is_closed: No
    
  - measure: count_lost
    type: count
    filters:
      is_closed: Yes
      is_won: No
    drill_fields: [opportunity.id, account.name, type] 

  - measure: win_percentage
    type: number
    sql: 100.00 * ${count_won} / NULLIF(${count_closed}, 0)
    value_format: '#0.00\%'
    
  - measure: open_percentage
    type: number
    sql: 100.00 * ${count_open} / NULLIF(${count}, 0)
    value_format: '#0.00\%' 
    
  - measure: count_new_business_won
    type: count
    filters:
      is_won: Yes
      opportunity.type: '"New Business"'
    drill_fields: [opportunity.id, account.name, type]    
    
  - measure: count_new_business
    type: count
    filters:
      opportunity.type: '"New Business"'
    drill_fields: [opportunity.id, account.name, type]   
  
  
- view: campaign
  extends: _campaign
  
  
- view: user
  extends: _user
  fields:
  
# dimensions #

  - filter: name_select
    suggest_dimension: name
      
  - filter: department_select
    suggest_dimension: department    
      
  - dimension: rep_comparitor
    sql: |
          CASE 
            WHEN {% condition name_select %} ${name} {% endcondition %}
              THEN '1 - ' || ${name}
            WHEN {% condition department_select %} ${account.business_segment} {% endcondition %}          
              THEN '2 - Rest of ' || ${account.business_segment}
          ELSE '3 - Rest of Sales Team'
          END
          
  - measure: average_revenue_pipeline
    type: number
    sql: ${opportunity.total_pipeline_revenue}/ NULLIF(${count},0)
    value_format: '[>=1000000]$0.00,,"M";[>=1000]$0.00,"K";$0.00'
    drill_fields: [account.name, opportunity.type, opportunity.closed_date, opportunity.total_acv]

  sets:
    opportunity_set:
      - average_revenue_pipeline
  
- view: contact
  extends: _contact
  fields:
  
  - dimension: name
    html: |
      <a href="mailto:{{ contact.email._value }}" target="_blank">
        <img src="https://upload.wikimedia.org/wikipedia/commons/4/4e/Gmail_Icon.png" width="16" height="16" />
      </a>
      {{ linked_value }}