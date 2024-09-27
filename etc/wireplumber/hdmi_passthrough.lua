-- HDMI Passthrough Enabler for WirePlumber
-- This script enables passthrough audio when an HDMI output is detected
-- Author: D.A.Pelasgus

-- Log the script actions
print("WirePlumber HDMI passthrough script loaded")

-- Function to check if a node supports HDMI passthrough
function is_hdmi_output(node)
    local node_name = node.properties["node.name"] or ""
    local device_name = node.properties["device.name"] or ""
    local media_class = node.properties["media.class"] or ""

    -- Check if the node is an HDMI output by looking at its properties
    return string.match(media_class, "Audio/Sink") and (string.match(node_name, "hdmi") or string.match(device_name, "hdmi"))
end

-- Function to enable passthrough for the given node
function enable_passthrough(node)
    print("Enabling passthrough for HDMI output: " .. (node.properties["node.name"] or "unknown"))

    -- Set the properties for passthrough
    node:call("set_param", "Node.Passthrough", "Spa:Pod:Bool", true)
end

-- Main function to monitor nodes and apply passthrough settings
function handle_new_node(node)
    if is_hdmi_output(node) then
        enable_passthrough(node)
    end
end

-- Monitor for new nodes
core:connect("object-added", function(_, node)
    if node.type == "PipeWire:Node" then
        handle_new_node(node)
    end
end)

-- Iterate over existing nodes and enable passthrough where necessary
for node in core:iterate_objects("node") do
    handle_new_node(node)
end
