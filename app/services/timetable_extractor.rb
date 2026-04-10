# 画像URLを受け取り、OpenAIのAPIを使用してタイムテーブルを抽出するサービスクラス
class TimetableExtractor
  # 画像からタイムテーブルを抽出するクラスメソッド
  def self.extract(tempfile)
    client = OpenaiClient.client
    # 画像をBase64エンコード
    image_base64 = Base64.strict_encode64(File.binread(tempfile))
    # 画像をURL形式に変換
    data_url = "data:image/jpeg;base64,#{image_base64}"
    response = client.responses.create(
      prompt: {
        id: Rails.application.credentials.dig(:openai, :timetable_extractor_prompt_id)
      },
      input: [
        {
          role: "user",
          content: [
            {
              type: "input_image",
              image_url: data_url
            }
          ]
        }
      ]
    )
    json = JSON.parse(response.output_text)
    { success: true, data: json }
  rescue JSON::ParserError => e
    Rails.logger.error("JSON parse error: #{e.message}")
    Rails.logger.error("AI output: #{response&.output_text}")
    { success: false, error: "画像解析結果の読み込みに失敗しました" }
  rescue StandardError => e
    Rails.logger.error(e)
    { success: false, error: "画像解析に失敗しました" }
  end
end
