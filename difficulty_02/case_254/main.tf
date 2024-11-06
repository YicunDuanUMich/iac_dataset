resource "aws_chime_voice_connector" "default" {
  name               = "vc-name-test"
  require_encryption = true
}

resource "aws_chime_voice_connector_streaming" "default" {
  voice_connector_id  = aws_chime_voice_connector.default.id
  data_retention = 5
}