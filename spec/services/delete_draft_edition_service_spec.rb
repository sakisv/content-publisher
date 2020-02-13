RSpec.describe DeleteDraftEditionService do
  let(:user) { create(:user) }

  describe ".call" do
    before do
      stub_any_publishing_api_discard_draft
      stub_any_publishing_api_unreserve_path
    end

    it "raises an error when the edition isn't current" do
      edition = create(:edition, current: false)

      expect { described_class.call(edition, user) }
        .to raise_error("Only current editions can be deleted")
    end

    it "raises an exception if the current edition is live" do
      edition = create(:edition, live: true)

      expect { described_class.call(edition, user) }
        .to raise_error("Trying to delete a live edition")
    end

    it "changes the edition's current flag" do
      edition = create(:edition)
      expect { described_class.call(edition, user) }
        .to change { edition.current? }.to(false)
    end

    it "sets a live edition to be current after a draft is discarded" do
      document = create(:document, :with_current_and_live_editions)
      live_edition = document.live_edition
      expect { described_class.call(document.current_edition, user) }
        .to change { document.current_edition }.to(live_edition)
    end

    it "sets the status of the edition to discarded" do
      edition = create(:edition)
      expect { described_class.call(edition, user) }
        .to change { edition.discarded? }.to(true)
    end

    it "delegates to the DeleteDraftAssetsService" do
      edition = create(:edition)
      expect(DeleteDraftAssetsService).to receive(:call).with(edition)
      described_class.call(edition, user)
    end

    it "discards the draft from the Publishing API" do
      edition = create(:edition)
      request = stub_publishing_api_discard_draft(edition.content_id)
      described_class.call(edition, user)
      expect(request).to have_been_requested
    end

    it "copes if the publishing API has a live but not draft edition" do
      edition = create(:edition)
      discard_draft_error = {
        error: {
          code: 422,
          message: "There is not a draft edition of this document to discard",
        },
      }
      stub_any_publishing_api_discard_draft
        .to_return(status: 422, body: discard_draft_error.to_json)

      described_class.call(edition, user)
      expect(edition).to be_discarded
    end

    it "doesn't capture all Publishing API unprocessable entity issues" do
      edition = create(:edition)
      discard_draft_error = {
        error: {
          code: 422,
          message: "New Publishing API problem",
        },
      }
      stub_any_publishing_api_discard_draft
        .to_return(status: 422, body: discard_draft_error.to_json)

      expect { described_class.call(edition, user) }
        .to raise_error(GdsApi::HTTPUnprocessableEntity)
    end

    it "delegates to the DiscardPathReservationsService for the first edition" do
      edition = create(:edition)
      expect(DiscardPathReservationsService).to receive(:call).with(edition)
      described_class.call(edition, user)
    end

    it "doesn't discard paths for later editions" do
      edition = create(:edition, number: 2)
      expect(DiscardPathReservationsService).not_to receive(:call).with(edition)
      described_class.call(edition, user)
    end

    it "raises an error and marks an edition as not synced when an API error occurs during discarding" do
      edition = create(:edition)
      stub_publishing_api_isnt_available

      expect { described_class.call(edition, user) }
        .to raise_error(GdsApi::BaseError)

      expect(edition.revision_synced?).to be(false)
    end
  end
end
