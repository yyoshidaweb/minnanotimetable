module PerformersHelper
  # URLを検証・整形する
  def safe_website_link(performer, **options)
    return unless performer.website_url.present?
    url = URI.parse(performer.website_url) rescue nil
    return unless url
    link_to url.to_s, **options do
      # URLテキスト + 外部リンクアイコンを並べて表示
      safe_join([
        url.to_s,
        content_tag(:span, "open_in_new",
                    class: "material-symbols-outlined ml-px align-text-top",
                    style: "font-size: 1.25rem;")
      ])
    end
  end
end
