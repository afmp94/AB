require "activerecord-import/base"
ActiveRecord::Import.require_adapter("postgresql")

module ImportCsv

  module Contacts

    class ImportService

      include Common::ContactsImportHelper

      BULK_INSERT = true

      attr_accessor :csv_file

      def initialize(csv_file)
        @csv_file = csv_file
      end

      def perform
        return if csv_file.user.nil?

        Rails.logger.info "[CSV.parsing] Processing new csv file..."
        start_time = Time.now
        begin
          process_csv
          csv_file.finish_import!
        rescue => e # parser error or unexpected error
          Rails.logger.error "[CSV.parsing] CSV Import Error: #{e.inspect}"
          csv_file.save_import_error(e)
          csv_file.failed!
          CsvImportFailureMailer.delay.notify(csv_file.id)
        end
        end_time = Time.now
        total_import_time = total_time(start_time, end_time)
        csv_file.update(total_import_time_in_ms: total_import_time)
      end

      def process_csv
        new_contacts           = []
        failed_rows_data       = []

        total_parsed_records   = 0
        total_imported_records = 0
        total_failed_records   = 0

        file = get_file(csv_file.file_url)
        start_parsing_time = Time.now

        CSV.foreach(file, headers: true, encoding: "iso-8859-1:utf-8") do |csv_row|
          total_parsed_records += 1
          Rails.logger.info "[CSV.parsing] Current processing row #{total_parsed_records}"

          begin
            new_contact = BuildContactWithAssociationsService.new(csv_row).perform

            set_contact_mandatory_fields(new_contact, csv_file.user) do |_new_contact|
              _new_contact.import_source = csv_file
            end

            if BULK_INSERT
              # When we want to do bulk insert without using Rails validation/ballbacks logic
              handle_validations(new_contact)
              set_other_fields(new_contact)
              set_primary_to_email_and_phone(new_contact)
              new_contacts << new_contact
            else
              new_contact.save!
            end

            total_imported_records += 1
            Rails.logger.info "[CSV.parsing] Current processing row got passed for importing #{total_imported_records}"
          rescue => e
            total_failed_records += 1
            Rails.logger.info "[CSV.parsing] Current processing row got failed #{total_failed_records}"
            failed_rows_data << [csv_row, e.message]
          end
        end
        end_parsing_time = Time.now
        total_parsing_time = total_time(start_parsing_time, end_parsing_time)
        Rails.logger.info "[CSV.parsing] TOTAL PARSING TIME: #{total_parsing_time} in miliseconds"

        delete_file(file)

        if BULK_INSERT && new_contacts.present?
          results = create_contacts_for(new_contacts)
          CallbacksService.new(results.ids).delay.process
        end

        store_parsed_imported_failed_data(total_parsed_records, total_imported_records, total_failed_records)
        create_invalid_records_for(csv_file, failed_rows_data)
        update_ungraded_contacts_count_for(csv_file.user)
        log_imported_rows
      end

      private

      def create_contacts_for(new_contacts)
        Rails.logger.info "New contact #{new_contacts.first.inspect}"
        Contact.import new_contacts, recursive: true, validate: false
      end

      def create_invalid_records_for(csv_file, failed_rows_data)
        invalid_records = []

        failed_rows_data.each do |data|
          invalid_records << CsvFile::InvalidRecord.new(
            csv_file_id: csv_file.id,
            original_row: data[0].to_csv,
            contact_errors: [data[1]]
          )
        end

        CsvFile::InvalidRecord.import invalid_records
      end

      def store_parsed_imported_failed_data(total_parsed_records, total_imported_records, total_failed_records)
        csv_file.update(total_parsed_records: total_parsed_records,
                        total_imported_records: total_imported_records,
                        total_failed_records: total_failed_records)
      end

      def log_imported_rows
        Rails.logger.info(
          "[CSV.parsing] Records parsed:: parsed: #{csv_file.total_parsed_records}"\
          " : imported: #{csv_file.total_imported_records} : failed: "\
          "#{csv_file.total_failed_records}"
        )
      end

      def get_file(file)
        if Rails.env.test?
          file
        else
          remote_csv_data = open(file).read
          tmp_csv_file = Tempfile.open file.gsub(/[^0-9a-z ]/i, ''), "#{Rails.root}/tmp"
          tmp_csv_file.write remote_csv_data.force_encoding("ISO-8859-1").encode("UTF-8")
          tmp_csv_file.rewind
          tmp_csv_file
        end
      end

      def delete_file(file)
        if !Rails.env.test?
          file.close
          file.unlink
        end
      end

      def total_time(start_time, end_time)
        (end_time - start_time) * 1000
      end

      def update_ungraded_contacts_count_for(user)
        if user
          user.update!(ungraded_contacts_count: user.contacts.active.ungraded.count)
        end
      end

    end

  end

end
