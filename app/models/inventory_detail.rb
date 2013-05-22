# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class InventoryDetail < ActiveRecord::Base
  belongs_to :inventory
  belongs_to :item

  validates_presence_of     :item, :item_id, :quantity
  validates_numericality_of :quantity, greater_than_or_equal_to: 0

  #delegate :service?, :product?, :name, :price, to: :item, prefix: true, allow_nil: true
end