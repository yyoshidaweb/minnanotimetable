module PerformersHelper
  # URLを検証・整形する
  def safe_website_link(performer, **options)
    return unless performer.website_url.present?
    url = URI.parse(performer.website_url) rescue nil
    return unless url
    link_to url.to_s, url.to_s, **options
  end
end
