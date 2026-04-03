module MarkdownHelper
  MARKDOWN_ALLOWED_TAGS = %w[p br strong em a ul ol li code pre blockquote].freeze
  MARKDOWN_ALLOWED_ATTRIBUTES = %w[href title].freeze

  def render_markdown(text)
    source = text.to_s.strip
    return "" if source.blank?

    html = Commonmarker.to_html(
      source,
      options: {
        parse: { smart: true },
        extension: { autolink: true, strikethrough: true, table: false, tagfilter: true }
      }
    )

    sanitize(html, tags: MARKDOWN_ALLOWED_TAGS, attributes: MARKDOWN_ALLOWED_ATTRIBUTES)
  end
end
