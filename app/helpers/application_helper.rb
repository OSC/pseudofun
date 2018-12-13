module ApplicationHelper

  def status_label(job, tag = :span)
    job ||= OpenStruct.new status: OSC::Machete::Status.not_submitted
    text = job.status.to_s

    label_class = 'badge-secondary'
    if job.failed?
      label_class = 'badge-danger'
    elsif job.passed?
      label_class = 'badge-success'
      text = "Completed"
    elsif job.active?
      label_class = 'badge-primary'
    end

    content_tag tag, class: %I(status-label badge #{label_class}) do
      text
    end
  end

end
