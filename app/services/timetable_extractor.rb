# 画像URLを受け取り、OpenAIのAPIを使用してタイムテーブルを抽出するサービスクラス
class TimetableExtractor
  MINI_MODEL = "gpt-5.4-mini"
  ADVANCED_MODEL = "gpt-5.4"
  STAGE_THRESHOLD = 10

  # 画像からタイムテーブルを抽出するクラスメソッド
  def self.extract(tempfile)
    client = OpenaiClient.client
    data_url = encode_image(tempfile)
    output_text = call_api(client, MINI_MODEL, data_url)
    json = JSON.parse(output_text)
    stages = json["stages"] || []
    # ステージ数が10以上の場合、高度なモデルで再度解析する
    if stages.size >= STAGE_THRESHOLD
      output_text = call_api(client, ADVANCED_MODEL, data_url)
      json = JSON.parse(output_text)
    end
    { success: true, data: json }
  rescue JSON::ParserError => e
    Rails.logger.error("JSON parse error: #{e.message}")
    Rails.logger.error("AI output: #{output_text}")
    { success: false, error: "画像解析結果の読み込みに失敗しました" }
  rescue StandardError => e
    Rails.logger.error(e)
    { success: false, error: "画像解析に失敗しました" }
  end

  class << self
    private

    # 画像をBase64エンコードしてdata URL形式に変換する
    def encode_image(tempfile)
      image_base64 = Base64.strict_encode64(File.binread(tempfile))
      "data:image/jpeg;base64,#{image_base64}"
    end

    # OpenAI APIを呼び出してレスポンステキストを取得する
    def call_api(client, model, data_url)
      response = client.responses.create(
        **TimetableExtractorPrompt.request_params(model: model, image_data_url: data_url)
      )
      response.output_text
    end
  end
end
