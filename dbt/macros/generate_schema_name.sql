{#
  Dùng đúng tên schema cấu hình (clean_view, dds, ...) thay vì mặc định của dbt
  là "<target_schema>_<custom_schema>" (vd. public_clean_view).
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
