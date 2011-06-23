# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
require 'active_support/concern'

module Models::AccountLedger
  module Money

    extend ActiveSupport::Concern

    included do
      before_validation :create_ledger_details, :if => :new_money?
      before_create     :add_description, :if => :money?
      before_create     :set_amount, :if => :money?

      validates_presence_of :account_id, :to_id, :if => :money?
      validate :valid_money_accounts, :if => :new_money?
    end

    module ClassMethods

      def new_money(params = {})
        params.transform_date_parameters!("date")
        params.symbolize_keys.assert_valid_keys( :operation, :account_id, :to_id, :amount, :reference, :date )

        ac = AccountLedger.new(params)
        ac.creator_id = UserSession.user_id
        def ac.money?; true; end
        ac.conciliation = false
        
        ac
      end
    end

    module InstanceMethods
      def new_money?
        new_record? and money?
      end

      def money?; false; end

      # Makes the conciliation to update accounts
      def conciliate_account
        return false unless active?

        account_ledger_details.each do |ac|
          ac.state = "con"
        end
        self.conciliation = true
        self.approver_id = UserSession.user_id

        self.save
      end


      private

        # Adds the description
        def add_description
          case operation
          when "in"    then self.description = "Ingreso por #{to}"
          when "out"  then self.description = "Egreso para #{to}"
          when "trans" then self.description = "Transferencia a #{to}"
          end
        end

        def create_ledger_details
          amt = amount_operation
          if account_id.present? and amount.present? and to_id.present?
            account_ledger_details.build(:account_id => account_id, :amount => amt, :currency_id => account.currency_id, :state => 'uncon')
            account_ledger_details.build(:account_id => to_id, :amount => -amt, :currency_id => account.currency_id, :state => 'uncon')
          end
        end

        # defines the amount based on the oeration
        def amount_operation
          case operation
          when "in"           then amount
          when "out", "trans" then -1 * amount
          end
        end

        # set the amounts only for trans, out
        def set_amount
          case operation
            when "out", "trans" then self.amount = -1 * amount
          end
        end

        # Validates the accounts
        def valid_money_accounts
          valid_account_id
          valid_to_id
        end

        # Check the account_id
        def valid_account_id
          err = false

          if account_id.present?
            begin
              ac = Account.org.find(account_id)
              err = true unless ac.accountable_type == "MoneyStore"
            rescue
              err = true
            end

            self.errors[:account_id] << I18n.t("errors.messages.inclusion") if err
          end
        end

        # Check the valid to_id based on the operation
        def valid_to_id
          err = false
          klass = trans? ? "MoneyStore" : "Contact"

          if to_id.present?
            begin
              ac = Account.org.find(to_id)
              err = true unless ac.accountable_type == klass
            rescue
              err = true
            end

            self.errors[:to_id] << I18n.t("errors.messages.inclusion") if err
          end
        end

    end
  end
end
