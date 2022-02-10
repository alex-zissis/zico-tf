resource "aws_route53_record" "autodiscover" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "autodiscover.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["mail.postale.io"]
}

resource "aws_route53_record" "autoconfig" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "autoconfig.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["mail.postale.io"]
}

resource "aws_route53_record" "shopify_ver" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "f72a9eab-455e-4323-99f4-9ab828b7f6cc.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["dns-verification.shopify.com"]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "www.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["alexz-dev.myshopify.com"]
}

resource "aws_route53_record" "_domainkey" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "s20220109919._domainkey.zico.dev"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCo+IM3pREaJK3yVesm/Y6cttHz1GOvpRzhpuq1aP9cAiickyR7mvZJliIPoTZ6KDwGXEfhfTbgTaZahkuQxxt7lJP8xCHF3COvdnI/cBLTUOVVFq86gerpi1dqy6EE5SJcRYvAVVchIMPcolcttv1y90FsrF6dDdUCTur+db/FFQIDAQAB"]
}

resource "aws_route53_record" "_domainkey-cm" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "cm._domainkey.zico.dev"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC7vCV9YcoQugPz/Nk+MFbNpJZfF4+u6uUbprTd6XOUzshBPjEelxPQNQC5/9DGTYD88XXGYw0tiCLV+nNsSxn09QbgARWrUNubG7NbCm+l7wi0+6B/8OB1o4l0DYBZohkurwRLhNAMhuZxPxTZimeCgvTg3NAhUncIgpg18Ocp1QIDAQAB"]
}

resource "aws_route53_record" "_dmarc" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "_dmarc.zico.dev"
  records = ["v=DMARC1; p=none; rua=mailto:dmarc-reports@zico.dev"]
}

resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "zico.dev"
  records = ["v=spf1 include:mailgun.org mx ~all"]
}

resource "aws_route53_record" "mx_domainkey" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "mx._domainkey.zico.dev"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC2YFwRHwllqzT4EWr84TCRSSyxdk5e8hOVivabNX26UbILulf3IEC+uT2EbRvS7KLxRRKW47kr0WgxNlTva3ON47Q8F0lnhjBRIN42qNWkkCrjU7QZpLh7LKn9d5ljO8KmnIV2tzMvMf9/ZWnB/+uSGingQQvxg9QSpMdLr6eWTwIDAQAB"]
}

resource "aws_route53_record" "email" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "email.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["mailgun.org"]
}

resource "aws_route53_record" "dev_spf" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "dev.zico.dev"
  records = ["v=spf1 include:mailgun.org ~all"]
}

resource "aws_route53_record" "krs_domainkey" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "krs._domainkey.dev.zico.dev"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDvnapQy+PSMSk2twAqk5NlxMThTk7v9q3a5dgjuS/kXilO2eHwzmmk5NVLH+xEp5qKdTkrAsCoJpb8qVl90vfQG9tQ+KAYCck2rz/boMu640EF8EMnKz0KGODzCg3R9KixBOuRXmWFyApnQb6iDOuL73OMEh8Dj+JmprISmdbBtQIDAQAB"]
}

resource "aws_route53_record" "email_dev" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "email.dev.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["mailgun.org"]
}

resource "aws_route53_record" "staging_spf" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "staging.zico.dev"
  records = ["v=spf1 include:mailgun.org ~all"]
}

resource "aws_route53_record" "k1_domainkey" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "k1._domainkey.staging.zico.dev"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDsMhWLPQhEF0bjzJnaHrmEpGyD3Sj63ZCC5bW74S93q8lwRqgskOd3IXKe9vMpbinJh1GWT5pF2vyX/UNXYmG3mQigDq2oaw8LOYF+QWZEIGxTctXOIiwZaD1P6JdFv32XXoBJPWlWczc6r8JW7Sad/J4OpK+g5nY/hm1RE5Oc4QIDAQAB"]
}

resource "aws_route53_record" "email_staging" {
  zone_id = aws_route53_zone.primary.zone_id
  name    = "email.staging.zico.dev"
  type    = "CNAME"
  ttl     = "300"
  records = ["mailgun.org"]
}

resource "aws_route53_record" "mail" {
    zone_id = aws_route53_zone.primary.zone_id
    name    = "mail.zico.dev"
    type    = "A"
    ttl     = "300"
    records = ["203.129.21.208"]
}

resource "aws_route53_record" "nas" {
    zone_id = aws_route53_zone.primary.zone_id
    name    = "nas.zico.dev"
    type    = "A"
    ttl     = "300"
    records = ["203.129.21.208"]
}

resource "aws_route53_record" "code" {
    zone_id = aws_route53_zone.primary.zone_id
    name    = "code.zico.dev"
    type    = "A"
    ttl     = "300"
    records = ["203.129.21.208"]
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "MX"
  ttl     = "300"
  name    = "zico.dev"
  records = ["0 mail.zico.dev"]
}

resource "aws_route53_record" "homemail_dkim" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "TXT"
  ttl     = "300"
  name    = "homemail._domainkey.zico.dev"
  records = ["k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCyNyEH1/D0jiCwHepZeMvxiwgRGpOLk45pXJ+mnsbbr9Q6WXORNFLyA9lHcgP/FNrFBFgJmAV34zqVAYCOdIpof3TwXoawTZwmaENxpIPxzb+qD2U4vT/V+fYNGovU5yANz4Oh0HJEMPPx6+uaHpS9fF8QGET25FKDV/YfvzhDNwIDAQAB"]
}