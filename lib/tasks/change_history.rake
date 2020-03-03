namespace :change_history do
  desc "Show all change notes for a document"
  task :show, %i[content_id] => :environment do |_, args|
    Edition
      .find_current(document: "#{args.content_id}:#{ENV.fetch('LOCALE', 'en')}")
      .change_history
      .each do |entry|
      puts [entry["id"], entry["public_timestamp"], entry["note"]].join(" | ")
    end
  end

  desc "Delete a single change note for a document, e.g. change_history:delete[content_id change-note-id]"
  task :delete, %i[content_id change_history_id] => :environment do |_, args|
    Tasks::EditionUpdater.call(args.content_id,
                               locale: ENV.fetch("LOCALE", "en"),
                               user_email: ENV["USER_EMAIL"]) do |edition, updater|
      entry = edition.change_history.find { |item| item["id"] == args.change_history_id }
      raise "No change history entry with id #{args.change_history_id}" unless entry

      updater.assign(change_history: edition.change_history - [entry])
    end
  end
end
