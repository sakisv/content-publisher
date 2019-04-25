# frozen_string_literal: true

RSpec.describe PublishService do
  describe "#publish" do
    context "when there is no live edition" do
      let(:edition) { create(:edition, :publishable) }
      let!(:publish_request) do
        stub_publishing_api_publish(edition.content_id,
                                    update_type: nil,
                                    locale: edition.locale)
      end

      it "publishes the current_edition" do
        PublishService.new(edition)
                      .publish(user: create(:user), with_review: true)

        expect(publish_request).to have_been_requested
        expect(edition.document.live_edition).to eq(edition)
        expect(edition).to be_published
        expect(edition).to be_live
      end

      it "can specify if edition is reviewed" do
        PublishService.new(edition)
                      .publish(user: create(:user), with_review: false)

        expect(publish_request).to have_been_requested
        expect(edition).to be_published_but_needs_2i
      end
    end

    context "when there is a live edition" do
      it "supersedes the live edition" do
        document = create(:document, :with_current_and_live_editions)
        current_edition = document.current_edition
        live_edition = document.live_edition
        stub_publishing_api_publish(document.content_id,
                                    update_type: nil,
                                    locale: document.locale)

        PublishService.new(current_edition)
                      .publish(user: create(:user), with_review: true)

        expect(document.live_edition).to eq(current_edition)
        expect(live_edition).to be_superseded
      end
    end

    it "calls the PublishAssetService" do
      document = create(:document, :with_current_and_live_editions)
      current_edition = document.current_edition
      stub_publishing_api_publish(document.content_id,
                                  update_type: nil,
                                  locale: document.locale)

      expect_any_instance_of(PublishAssetService).to receive(:publish_assets)

      PublishService.new(current_edition)
        .publish(user: create(:user), with_review: true)
    end
  end
end
