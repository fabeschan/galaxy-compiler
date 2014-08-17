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
                Process p = Runtime.getRuntime().exec("./out " + testcaseName);
                BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
                StringBuilder builder = new StringBuilder();
                String line = null;
                while ( (line = br.readLine()) != null) {
                   builder.append(line);
                   builder.append(System.getProperty("line.separator"));
                }
                String result = builder.toString();

                String text = new Scanner(g).useDelimiter("\\A").next();
                System.out.printf("Test Case [%s]: %s\n", s, result.equals(text)? "PASS":"FAIL");
            }
            catch (Exception err){ err.printStackTrace(); }

        }

    }

}
