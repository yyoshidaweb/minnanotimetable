class Performer < ApplicationRecord
  belongs_to :event
  belongs_to :performer_name_tag

  has_many :performances, dependent: :destroy
  has_many :performer_favorites, dependent: :destroy

  # 出演者をお気に入り登録しているユーザーの一覧を取得したいときに使うエイリアス
  has_many :favorited_users, through: :performer_favorites, source: :user
end
