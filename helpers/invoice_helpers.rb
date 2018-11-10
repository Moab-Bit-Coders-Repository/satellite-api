module Sinatra
  module InvoiceHelpers
    
    def fetch_invoice_by_lid
      Invoice.first(:lid => params[:lid]) || halt(404, {:message => "Not found", :errors => ["Invalid invoice id"]}.to_json)
    end
    
    def authorize_invoice!(invoice)
      if invoice.charged_auth_token != params[:charged_auth_token]
        halt 401, {:message => "Unauthorized", :errors => ["Invalid authentication token"]}.to_json
      else
        invoice
      end
    end
    
    def invoice
      @invoice ||= authorize_invoice!(fetch_invoice_by_lid)
    end

  end
  helpers InvoiceHelpers
end
