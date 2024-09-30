import java.time.Instant;
import java.time.format.DateTimeParseException;

public class Millis {
    public static void main(String[] args) {
        if (args.length != 1) usage();

        final var s = args[0];
        try {
            System.out.println(Instant.ofEpochMilli(Long.parseLong(s)));
        } catch (NumberFormatException e) {
            try {
                System.out.println(Instant.parse(s).toEpochMilli());
            } catch (DateTimeParseException u) {
                System.err.println("Cannot parse: " + s);
                usage();
            }
        }
    }

    static void usage() {
        System.err.println("Usage:   java -jar millis.jar timestamp-or-date\nExample: java -jar millis.jar 1707916432177\nExample: java -jar millis.jar 2024-02-14T13:13:52.177Z");
        System.exit(1);
    }
}
