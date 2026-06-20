# タイムテーブル画像解析用のOpenAIプロンプト設定
module TimetableExtractorPrompt
  INSTRUCTIONS = <<~INSTRUCTIONS.strip
    - Extract music festival timetable data from the image.
    - If the image is not a music festival timetable, set "stages" to an empty array and do not generate any stage or performance data.
    - Recognize all stage columns and the time column without omission, and output stages in left-to-right order as they appear in the image.
    - Extract all performer names and start times visible in the image; do not omit any stage or performance under any circumstances.
    - If a start time is written inside the performance block, use it.
    - If not, use the nearest time from the time column.
    - If stage or performer names are unclear, assign unique placeholder names such as Unknown-1, Unknown-2, etc., separately for stages and performers.
    - Do not reuse the same Unknown label; always increment the suffix to ensure uniqueness within each category.
    - Ensure no two performances on the same stage share the same start time; if duplicates occur, keep only the lexicographically earliest performer and discard the others.
  INSTRUCTIONS

  JSON_SCHEMA = {
    "type" => "object",
    "properties" => {
      "stages" => {
        "type" => "array",
        "description" => "List of festival stages, each with its own performances.",
        "items" => {
          "type" => "object",
          "properties" => {
            "stage_name" => {
              "type" => "string",
              "description" => "Name of the stage."
            },
            "performances" => {
              "type" => "array",
              "description" => "List of performances on this stage.",
              "items" => {
                "type" => "object",
                "properties" => {
                  "performer_name" => {
                    "type" => "string",
                    "description" => "Name of the performer or group."
                  },
                  "start_time" => {
                    "type" => "string",
                    "description" => "Scheduled start time in 24-hour HH:MM format.",
                    "pattern" => "^([01][0-9]|2[0-3]):[0-5][0-9]$"
                  }
                },
                "required" => [ "performer_name", "start_time" ],
                "additionalProperties" => false
              }
            }
          },
          "required" => [ "stage_name", "performances" ],
          "additionalProperties" => false
        }
      }
    },
    "required" => [ "stages" ],
    "additionalProperties" => false
  }.freeze

  # OpenAI Responses API へのリクエストパラメータを生成する
  def self.request_params(model:, image_data_url:)
    {
      model: model,
      instructions: INSTRUCTIONS,
      input: [
        {
          role: "user",
          content: [
            {
              type: "input_image",
              image_url: image_data_url
            }
          ]
        }
      ],
      reasoning: { effort: :low },
      text: {
        format: {
          type: :json_schema,
          name: "timetable_schema",
          strict: true,
          schema: JSON_SCHEMA
        },
        verbosity: :medium
      }
    }
  end
end
