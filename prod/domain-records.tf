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
  records = ["v=spf1 mx ~all"]
}

resource "aws_route53_record" "mx" {
  zone_id = aws_route53_zone.primary.zone_id
  type    = "MX"
  ttl     = "300"
  name    = "zico.dev"
  records = ["0 mail.postale.io"]
}