unless File.respond_to?(:exists?)
    class File
      def self.exists?(*args)
        self.exist?(*args)
      end
    end
end
