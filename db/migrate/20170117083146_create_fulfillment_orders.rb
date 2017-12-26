# create fullfillment table
class CreateFulfillmentOrders < ActiveRecord::Migration
  def change
    create_table :fulfillment_orders do |t|
      t.string :number
      t.string :transaction_number
      t.string :order_number
      t.string :status_code
      t.string :status_message
      t.text :raw_request
      t.text :raw_response
      t.string :type

      t.timestamps
    end
  end
end
