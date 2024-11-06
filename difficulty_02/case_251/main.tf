resource "aws_chime_voice_connector" "default" {
  name               = "vc-name-test"
  require_encryption = true
}

resource "aws_chime_voice_connector_logging" "default" {
  enable_sip_logs          = false
  enable_media_metric_logs = true
  voice_connector_id       = aws_chime_voice_connector.default.id
}