# frozen_string_literal: true

class ScheduleController < ApplicationController
  def save_scheduled_publishing_datetime
    Document.transaction do
      document = Document.with_current_edition.lock.find_by_param(params[:id])
      edition = document.current_edition

      checker = Requirements::ScheduledDatetimeChecker.new(permitted_params)
      issues = checker.pre_submit_issues

      if issues.any?
        href = { scheduled_datetime: "#scheduled_publishing_datetime" }
        flash["alert_with_items"] = {
          title: I18n.t!("requirements.scheduled_datetime.title"),
          items: issues.items(hrefs: href),
        }
        flash[:scheduled_publishing_params] = permitted_params
        redirect_to document_path(document)
        return
      end

      set_scheduled_publishing_datetime(edition, checker.parsed_datetime)

      redirect_to document_path(document)
    end
  end

  def clear_scheduled_publishing_datetime
    Document.transaction do
      document = Document.with_current_edition.lock.find_by_param(params[:id])
      edition = document.current_edition

      set_scheduled_publishing_datetime(edition)

      redirect_to document_path(document)
    end
  end

  def confirmation
    document = Document.with_current_edition.find_by_param(params[:id])
    @edition = document.current_edition

    unless @edition.schedulable?
      # FIXME: this shouldn't be an exception but we've not worked out the
      # right response - maybe bad request or a redirect with flash?
      raise "Scheduled publishing date and time must be at least 15 minutes in the future."
    end
  end

  def schedule
    Document.transaction do
      document = Document.with_current_edition.lock!.find_by_param(params[:id])
      edition = document.current_edition

      if edition.scheduled_publishing_datetime.blank?
        # FIXME: this shouldn't be an exception but we've not worked out the
        # right response - maybe bad request or a redirect with flash?
        raise "Cannot schedule an edition to be published without setting a publishing date and time."
      end

      reviewed = review_params == "reviewed"
      ScheduleService.new(edition).schedule(user: current_user, reviewed: reviewed)

      redirect_to scheduled_path(document)
    end
  end

  def scheduled
    document = Document.with_current_edition.find_by_param(params[:id])
    @edition = document.current_edition
  end

private

  def permitted_params
    params.require(:scheduled).permit(:year, :month, :day, :time)
  end

  def review_params
    params.require(:review_status)
  end

  def set_scheduled_publishing_datetime(edition, datetime = nil)
    current_revision = edition.revision
    new_revision = current_revision.build_revision_update(
      { scheduled_publishing_datetime: datetime }, current_user
    )
    if new_revision != current_revision
      edition.assign_revision(new_revision, current_user).save!
      create_timeline_entry(edition, new_revision, datetime)
    end
  end

  def create_timeline_entry(edition, revision, datetime)
    entry_type = if datetime
                   :scheduled_publishing_datetime_set
                 else
                   :scheduled_publishing_datetime_cleared
                 end
    TimelineEntry.create_for_revision(entry_type: entry_type,
                                      revision: revision,
                                      edition: edition,
                                      details: nil,
                                      created_by: current_user)
  end
end