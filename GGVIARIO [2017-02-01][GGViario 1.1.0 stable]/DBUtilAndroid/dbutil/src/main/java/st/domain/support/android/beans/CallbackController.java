package st.domain.support.android.beans;

import android.os.Bundle;
import android.util.Log;

import st.domain.support.android.model.CallbackClient;
import st.domain.support.android.sql.DMLite;

import java.util.HashMap;
import java.util.Map;


public class CallbackController
{
	public static  final HashMap<CharSequence, CallbackClient> map = new HashMap<>();
	private String tag = CallbackController.class.getSimpleName();


	/**
	 * Entrar na net entra saindo houver uma outra instancia da mesma na net
	 */
	public static void inOutingNet(CallbackClient client)
	{
		outNet(client);
		inNet(client);
	}
	public static boolean inNet(CallbackClient callbackClient)
	{
		return registerClient(callbackClient);
	}

	public static void outNet(CallbackClient callbackClient)
	{
		unRegister(callbackClient);
	}

	private static void unRegister(CallbackClient callbackClient)
	{
		CharSequence id = callbackClient.getIdentifier();
		if(map.containsKey(id))
			map.remove(id);
	}


	/**
	 * Remover o registro de um callbak
	 * @param client
	 * @return
     */
	public static boolean registerClient(CallbackClient client)
	{
		if(map.containsKey(client.getIdentifier())) return false;
		map.put(client.getIdentifier(), client);
		return true;
	}
	
	public static CallbackClient findNet(CharSequence key)
	{
		return map.get(key);
	}
	
	

	static synchronized public boolean sendTo(CallbackClient origem, CharSequence destineId, String sumary, Object... sendValues)
	{
		CallbackClient fragmentTo = findNet(destineId);
		return nextSend(CallbackClient.SendType.ONE, origem, fragmentTo, destineId, sumary, sendValues);
	}


	static synchronized public void sendAll(CallbackClient origem, String sendKey, Object... sendValue)
	{
		
		for (Map.Entry<CharSequence, CallbackClient> item: map.entrySet())
			if(!item.getValue().equals(origem))
			{
				nextSend(CallbackClient.SendType.ALL, origem, item.getValue(), item.getKey(), sendKey, sendValue);
			}
	}

	/**
	 * Enviar uma intemção para um gupo de callback
	 * @param origem
	 * @param sumary
	 * @param destines
	 * @param sendValues
     * @return
     */
	static synchronized public boolean sendIn(CallbackClient origem, String sumary, CharSequence destines[], Object... sendValues)
	{
		boolean result = true;
		if(destines == null)
		{
			Log.e(CallbackController.class.getSimpleName(), "KeyboradSimpleNumbers-> destinataries not found");
			return  false;
		}
		for(CharSequence destine: destines)
			if(!CallbackController.sendTo(origem, destine, sumary, sendValues))
				result = false;
		return  result;
	}

	/**
	 * Enviar para o proximo cliente callback
	 * @param origem O fragmento da origem
	 * @param destine O fragmento do destino
	 * @param summary O codigo da informacao
	 * @param sendValue A informacao
	 */
	protected static boolean nextSend(CallbackClient.SendType sendType, CallbackClient origem, CallbackClient destine,
									  CharSequence destineId, String summary, Object... sendValue)
	{
		//O dado so pode ser inviado se o frgamento for uma instancia de callbackCLiente
		if(destine != null)
		{
			Log.i(CallbackController.class.getSimpleName(), CallbackController.class.getSimpleName()+"-> SENDING | intent{origem:\""+origem.getIdentifier()+"\", destine:\""+destineId+"\", summary:\""+summary+"\", type:\""+sendType+"\", arguments"+ DMLite.toText(sendValue)+"}");
			destine.onReceive(sendType, origem, summary, sendValue);
			return true;
		}
		else
		{
			Log.e(CallbackController.class.getSimpleName(), CallbackController.class.getSimpleName()+"-> SEND FAILED | intent{origem:\""+origem.getIdentifier()+"\", destineKey:\""+destineId+"\",  type:\""+sendType+"\", arguments"+ DMLite.toText(sendValue)+"}");
		}
		return false;
	}

	public static Bundle query(CallbackClient clientRequired, CharSequence clientResponse, String querySummary, Object ... values)
	{
		if(clientRequired == null)
		{
			Log.w(CallbackController.class.getSimpleName(), "Cliente required is null");
		}

		CallbackClient response = findNet(clientResponse);
		if(response != null) return findNet(clientResponse).query(clientRequired, querySummary, values);
		else
		{
			Log.e(CallbackController.class.getSimpleName(), CallbackController.class.getName()+"-> NOT FOUND CLIENT "+response+" FOR "+clientRequired.getIdentifier());
			return null;
		}
	}

	public String getTag() {
		return tag;
	}

	public void setTag(String tag) {
		this.tag = tag;
	}
}
