# frozen_string_literal: true

RSpec.feature "Set scheduled publishing date and time passes before scheduling" do
  scenario do
    given_there_is_an_edition_with_past_scheduled_publishing_datetime
    when_i_visit_the_summary_page
    then_i_cannot_see_a_schedule_link
  end

  def given_there_is_an_edition_with_past_scheduled_publishing_datetime
    datetime = Time.zone.now - 1
    @edition = create(:edition, scheduled_publishing_datetime: datetime)
  end

  def when_i_visit_the_summary_page
    visit document_path(@edition.document)
  end

  def then_i_cannot_see_a_schedule_link
    expect(page).not_to have_button("Schedule")
  end
end