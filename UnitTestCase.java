import java.io.*;
import java.util.Scanner;

class UnitTestCase {
    public static String unittestsDir = "unittests";
    public static void main(String[] argv) {
        for (String s: argv){

            String testcaseName = String.format("%s/%s.testcase", unittestsDir, s);
            String resultName = String.format("%s/%s.result", unittestsDir, s);

            File f = new File(testcaseName);
            File g = new File(resultName);
            if (!f.exists()){
                System.out.printf("Error: %s: file does not exist.\n", testcaseName);
                System.exit(1);
            }
            if (!g.exists()){
                System.out.printf("Error: %s: file does not exist.\n", resultName);
                System.exit(1);
            }

            try {
                boolean pass = true;

                // Get process output
                Process p = Runtime.getRuntime().exec("./out " + testcaseName);
                BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
                String line = null;

                // Get test result file
                Scanner scanner = new Scanner(g);

                while ( (line = br.readLine()) != null && scanner.hasNextLine() ) {
                   String resultLine = scanner.nextLine();

                    if (!resultLine.equals(line)) {
                        System.out.printf("   [%s]: result mismatch:\n", s);
                        System.out.printf("   [testcase]: %s\n", line);
                        System.out.printf("   [results] : %s\n", resultLine);
                        pass = false;
                        break;
                    }
                }
                System.out.printf("Test Case [%s]: %s\n", s, pass ? "PASS":"FAIL");

                scanner.close();
            }
            catch (Exception err){ err.printStackTrace(); }

        }

    }

}
