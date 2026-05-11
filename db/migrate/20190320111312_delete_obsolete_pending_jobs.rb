class DeleteObsoletePendingJobs < ActiveRecord::Migration[4.2]
  def up
    Delayed::Job.all.each do |job|
      if job.name == "FinalizeAccountInvoices" ||
          job.name == "UpdateAccountInvoices" ||
          job.name == "UpdateBillablePeriods"
        job.delete
      end
    end
  end
end
