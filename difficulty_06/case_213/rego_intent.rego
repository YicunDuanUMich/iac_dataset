package main

import future.keywords.in

default allow = false

# Check for MSK Connect Custom Plugin creation
msk_connect_plugin_created(resources) {
some resource in resources
resource.type == "aws_mskconnect_custom_plugin"
resource.change.actions[_] == "create"
}

# Check if the custom plugin uses a ZIP file
plugin_content_type_valid(resource) {
resource.type == "aws_mskconnect_custom_plugin"
resource.change.after.content_type == "ZIP"
}

# Check for the custom plugin name
plugin_name_valid(resource) {
resource.type == "aws_mskconnect_custom_plugin"
resource.change.after.location[0].s3[0].file_key == "debezium.zip" 
}

# Check for MSK Connect Connector creation
msk_connect_connector_created(resources) {
some resource in resources
resource.type == "aws_mskconnect_connector"
resource.change.actions[_] == "create"
}

# Check if the connector uses the custom plugin
connector_uses_custom_plugin(resource) {
resource.type == "aws_mskconnect_connector"
input.resource_changes[_].type == "aws_mskconnect_custom_plugin"
}

# Aggregate checks for custom plugin and connector
allow {
msk_connect_plugin_created(input.resource_changes)
some resource in input.resource_changes
plugin_content_type_valid(resource)
plugin_name_valid(resource)
msk_connect_connector_created(input.resource_changes)
some resource2 in input.resource_changes
connector_uses_custom_plugin(resource2)
}