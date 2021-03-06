module WhitehallImporter
  class IntegrityChecker::UnpublishingCheck
    attr_reader :edition, :unpublishing

    def initialize(edition, unpublishing)
      @edition = edition
      @unpublishing = unpublishing
    end

    def expected_type?
      unpublishing["type"] == expected_type
    end

    def expected_type
      return "withdrawal" if edition.withdrawn?

      edition.status.details.redirect? ? "redirect" : "gone"
    end

    def expected_unpublishing_time?
      return true unless edition.withdrawn?

      unpublishing_time_matches?
    end

    def expected_unpublishing_time
      edition.status.details&.withdrawn_at
    end

    def expected_alternative_path?
      return true unless edition.removed?

      unpublishing["alternative_path"] == edition.status.details.alternative_url
    end

    def expected_alternative_path
      edition.status.details&.alternative_url
    end

    def expected_explanation?
      Sanitize.clean(unpublishing["explanation"]).squish ==
        Sanitize.clean(edition_explanation_html).squish
    end

  private

    def unpublishing_time_matches?
      IntegrityChecker.time_matches?(unpublishing["unpublished_at"],
                                     expected_unpublishing_time&.rfc3339)
    end

    def edition_explanation_html
      explanation = edition.status.details.try(:public_explanation) ||
        edition.status.details.try(:explanatory_note)

      Govspeak::Document.new(explanation).to_html
    end
  end
end
