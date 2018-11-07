# frozen_string_literal: true

require "spec_helper"

RSpec.describe DocumentPublishingService do
  describe "#publish_draft" do
    it "keeps track of the publication state" do
      stub_any_publishing_api_put_content
      document = create(:document)
      allow(document).to receive(:update!)

      DocumentPublishingService.new.publish_draft(document)

      expect(document).to have_received(:update!).with(publication_state: "sending_to_draft")
      expect(document).to have_received(:update!).with(publication_state: "sent_to_draft")
    end
  end

  describe "#publish" do
    it "keeps track of the publication state" do
      stub_any_publishing_api_publish
      document = create(:document)
      allow(document).to receive(:update!)

      DocumentPublishingService.new.publish(document, "reviewed")

      expect(document).to have_received(:update!).with(publication_state: "sending_to_live", review_state: "reviewed")
      expect(document).to have_received(:update!).with(publication_state: "sent_to_live", has_live_version_on_govuk: true)
    end
  end

  describe "#discard_draft" do
    it "keeps track of the publication state" do
      document = create(:document)
      stub_publishing_api_discard_draft(document.content_id)
      allow(document).to receive(:update!)

      DocumentPublishingService.new.discard_draft(document)

      expect(document).to have_received(:update!).with(publication_state: "changes_not_sent_to_draft")
    end
  end
end
