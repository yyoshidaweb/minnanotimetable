class OpenaiClient
  # OpenAIクライアントを初期化するクラスメソッド
  def self.client
    OpenAI::Client.new(
      api_key: Rails.application.credentials.dig(:openai, :api_key)
    )
  end
end
